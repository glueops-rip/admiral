# admiral

## Overview

This admiral repo lets you orchestrate the deployment and management of a captain cluster with all the services. When running the `terraform`,`helm`, and other CLI commands mentioned in this `README.md`, please assume you are a level above **this** folder. For example, the `-chdir` flag means running the terraform within a particular folder, and the `-state` lets you save it somewhere else. The ideal way to look at this `admiral` repository is that it is a software package. Right now, it's a series of git repositories CLI commands, but we plan to automate this further to where we have a single API call to do all this automation for you.

### Deploying your cluster

**IMPORTANT: You can only use 1 Cloud Provider**

#### Amazon Web Services (AWS)

#### Deployment

See docs in: https://github.com/GlueOps/terraform-module-cloud-aws-kubernetes-cluster

```bash
terraform -chdir=admiral/kubernetes-cluster/aws init
terraform -chdir=admiral/kubernetes-cluster/aws apply -state=$(pwd)/terraform_states/kubernetes-cluster.terraform.tfstate -var-file=$(pwd)/captain_configuration.tfvars
```

##### Authentication for maintenance/post-deployment tasks

```bash
aws eks update-kubeconfig --region us-west-2 --name captain-cluster
```

#### Google Cloud Platform (GCP)

##### Deployment

See docs in: <https://github.com/GlueOps/terraform-module-cloud-gcp-kubernetes-cluster>

```bash
terraform -chdir=admiral/kubernetes-cluster/gcp init
terraform -chdir=admiral/kubernetes-cluster/gcp apply -state=$(pwd)/terraform_states/kubernetes-cluster.terraform.tfstate -var-file=$(pwd)/captain_configuration.tfvars
```

##### Authentication for maintenance/post-deployment tasks

```
gcloud auth activate-service-account --key-file=creds.json
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials gke --region us-central1 --project <PROJECT_ID> #Should be in your captain_configuration.tfvars
```

### Deploying K8s Apps

#### Prerequisites

- You need to have a connection to the k8s server. Per your Cloud provider the authentication methods will vary.
- You need to have a proper `captain.yaml` (see below)

#### Deploying the GlueOps Platform

```bash
kubectl create ns glueops-core
helm template randomidhere -f captain.yaml --dependency-update --namespace=glueops-core ./admiral/glueops-platform | kubectl -n glueops-core apply -f -
helm template randomidhere -f captain.yaml --dependency-update --namespace=glueops-core ./admiral/glueops-platform | kubectl -n glueops-core apply -f -
```

**_Note: you run the command twice because the CRD's get installed on the very first deployment._**

### Vault Setup

#### Intialize Vault

See docs in: <https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization>

```bash
terraform -chdir=admiral/hashicorp-vault/init init
terraform -chdir=admiral/hashicorp-vault/init apply -state=$(pwd)/terraform_states/vault-init.terraform.tfstate
```

#### Configure Vault

See docs in: https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration

```bash
terraform -chdir=admiral/hashicorp-vault/configuration init
terraform -chdir=admiral/hashicorp-vault/configuration apply -state=$(pwd)/terraform_states/vault-configuration.terraform.tfstate -var-file=$(pwd)/captain_configuration.tfvars
```

## Cheat Sheet

- To do much of anything, you probably need to authenticate with the K8s cluster. See the Cloud specific Authentication details **_above_**.
- Whenever running terraform against vault you need a connection to vault: `kubectl -n glueops-core-vault port-forward svc/vault-ui 8200:8200`
  - Don't forget to add the SSL cert to your CA Store by running: `export SSL_CERT_FILE=$(pwd)/ca.crt`
- When making IaC updates to the Kubernetes cluster itself (ex., new node pools or updating cluster version, VPC peering, etc.) you must authenticate to that cloud provider and those instructions will be in the terraform module that you used to deploy the cluster in the `##### Deployment` section
- Remember all commands in this document assume you are "above" the admiral folder.




## Making your captain.yaml

- `captain_domain` is pretty straight forward. It'll be used as the suffix url for argocd, grafana, vault, and any other services that come out of the box in the glueops platform.
- `cloudflare_api_token` should be a token with edit access to your zone. It will be used by `cert-manager` to create SSL certs via DNS verification through ZeroSSL and it will be used by `external-dns` to upsert DNS records in cloudflare so that your services can be exposed on the web via DNS.
- `zerossl_eab_kid` and `zerossl_eab_hmac_key` can be obtained for free with an account under zerossl.com
- todo: finish these docs


```yaml
captain_domain: <yournamesgoeshere.glueops.rocks>
cloudflare_api_token: XXXXXXXXXXXXXXXXXXXXXXXXXX
certManager:
  zerossl_eab_kid: XXXXXXXXXXXXXXXXXXXXXXXXXX
  zerossl_eab_hmac_key: XXXXXXXXXXXXXXXXXXXXXXXXXX
gitHub:
  customer_github_org_and_team: "glueops-rocks:developers"
grafana:
  github_client_id: XXXXXXXXXXXXXXXXXXXXXXXXXX
  github_client_secret: XXXXXXXXXXXXXXXXXXXXXXXXXX
  github_org_names: GlueOps glueops-rocks
argo-cd:
  server:
    ingress:
      hosts: ["argocd.yournamesgoeshere.glueops.rocks"]
      tls: 
        - 
          hosts: 
            - argocd.yournamesgoeshere.glueops.rocks
          secretName: argocd-tls
    config:
      url: "https://argocd.yournamesgoeshere.glueops.rocks"
      dex.config: |
        connectors:
          - type: github
            id: github
            name: GitHub
            config:
              clientID: XXXXXXXXXXXXXXXXXXXXXXXXXX
              clientSecret: XXXXXXXXXXXXXXXXXXXXXXXXXX
              orgs:
              - name: GlueOps
              - name: glueops-rocks
              loadAllGroups: true
    rbacConfig:
      policy.csv: |
        g, GlueOps:argocd_super_admins, role:admin
        g, glueops-rocks:developers, role:developers
        p, role:developers, clusters, get, *, allow
        p, role:developers, *, get, development, allow
        p, role:developers, repositories, *, development/*, allow
        p, role:developers, applications, *, development/*, allow
        p, role:developers, exec, *, development/*, allow
```