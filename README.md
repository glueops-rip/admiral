# admiral

## Overview

This admiral repo lets you orchestrate the deployment and management of a captain cluster with all the services. When running the `terraform`,`helm`, and other CLI commands mentioned in this `README.md`, please assume you are a level above **this** folder. For example, the `-chdir` flag means running the terraform within a particular folder, and the `-state` lets you save it somewhere else. The ideal way to look at this `admiral` repository is that it is a software package. Right now, it's a series of git repositories CLI commands, but we plan to automate this further to where we have a single API call to do all this automation for you.

### Getting Started

Since the admiral repo is intended to be thought of as a software package, usage involves downloading this repository and following the below installation instructions.

[GlueOps Team](https://github.com/internal-GlueOps/team/wiki/Admiral-Repository-Usage-for-GlueOps-Team-Members)

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
gcloud container clusters get-credentials gke --region us-central1-a --project <PROJECT_ID> #Should be in your captain_configuration.tfvars. Remove the `-a` if you are using regional
```

### Deploying K8s Apps

#### Prerequisites

- Connection to the Kubernetes server. The authentication methods will vary by Cloud Provider and are documented above
- A proper `captain.yaml` (see below)

#### Deploying the GlueOps Platform

```bash
kubectl create ns glueops-core
helm template captain -f captain.yaml --dependency-update --namespace=glueops-core ./admiral/glueops-platform | kubectl -n glueops-core apply -f -
helm template captain -f captain.yaml --dependency-update --namespace=glueops-core ./admiral/glueops-platform | kubectl -n glueops-core apply -f -
```

To check items pending apply, use:

```bash
helm template captain -f captain.yaml --dependency-update --namespace=glueops-core ./admiral/glueops-platform | kubectl -n glueops-core diff -f -
```

**_Notes:_**<br>
**_- It can take up to 10 minutes for the services on kubernetes to come up.  Login to ArgoCD with `admin` credentials to monitor the status of the deployment. See `Cheat Sheet` below for details about logging in if you need them._**<br>
**_- You run the command twice because the CRD's get installed on the very first deployment._**

### Vault Setup

#### Intialize Vault

See docs in: <https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization>

From the root directory of your repository, initialize vault using the following commands
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

### Tips

- To do much of anything, you probably need to authenticate with the K8s cluster. See the Cloud specific Authentication details **_above_**.
- Whenever running terraform against vault you need a connection to vault: `kubectl -n glueops-core-vault port-forward svc/vault-ui 8200:8200`
  - Don't forget to add the SSL cert to your CA Store by running: `export SSL_CERT_FILE=$(pwd)/ca.crt`
- When making IaC updates to the Kubernetes cluster itself (ex., new node pools or updating cluster version, VPC peering, etc.) you must authenticate to that cloud provider and those instructions will be in the terraform module that you used to deploy the cluster in the `##### Deployment` section
- Remember all commands in this document assume you are "above" the admiral folder.

### Using the Cluster
- Service Locations
  - **ArgoCD** - `argocd.{captain_domain from captain.yaml}`
  - **Vault** - `vault.{captain_domain from captain.yaml}`
  - **Grafana** - `grafana.{captain_domain from captain.yaml}`
- Accessing Services
  - GitHub OAuth - to confirm OAuth access was configured correctly
    - **ArgoCD** - Click "log in via github" and select the relevant organization, which was configured in the `captain.yaml` at `gitHub.customer_github_org_and_team:`
    - **Vault**  - [Create a GitHub Personal Access Token](https://github.com/settings/tokens) with permission to `read:org`.  Paste the token into the Vault UI.
    - **Grafana** - Click "Sign in with GitHub" and select the relevant organization, which was configured in the `captain.yaml` at `gitHub.customer_github_org_and_team:`
  - Admin
    - **ArgoCD** - username: `admin`, retrieve the password using:
      
      ```bash
      kubectl -n glueops-core get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
      ```
    - **Vault**
      - Retrieve the `root_token` from the tfstatefile of the Vault init TF apply (`$(pwd)/terraform_states/vault-init.terraform.tfstate`)
      - Select `Other` on the login page and use `Token` as the `Method`
      - Paste the `root_token` value as the `Token`

    - **Grafana** - username: `admin`, retrieve the password using:
      
      ```bash
      kubectl -n glueops-core-kube-prometheus-stack get secret kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
      ```


## Making your captain.yaml

- `captain_domain` -- The Route53 subdomain for the services on your cluster.  It will be used as the suffix url for argocd, grafana, vault, and any other services that come out of the box in the glueops platform.  _Note: you need to create this before using this repo as this repo does not provision DNS Zones for you._
- `aws_accessKey`,`aws_secretKey`,`aws_region` are your AWS credentials to update your `captain_domain` in route53
- `zerossl_eab_kid` and `zerossl_eab_hmac_key` can be obtained for free with an account under zerossl.com.  To retrieve these values, log in to the relevant zerossl account for your zone and navigate to the [developer page](https://app.zerossl.com/developer). **_Note: use a personal ZeroSSL account, and not a shared account - this avoids unintended consequences._**
- `grafana` - `github_client_id`, `github_client_secret`: Register a [new OAuth App](https://github.com/settings/applications/new)
  - `Application name`: use something logical that you can find later
  - `Homepage URL`: format - https://grafana.<captain_domain>/login
  - `Authorization callback URL`: format - https://grafana.<captain_domain>/login/github
  - Retrieve values needed in `captain.yaml` after the OAuth app is created.
- `argo-cd` - similar to `grafana`, register a new OAuth app and retrieve the associated `github_client_id` and `github_client_secret`
  - `Application name`: use something logical that you can find later
  - `Homepage URL`: format - https://argocd.<client_domain>
  - `Authorization callback URL`: format - https://argocd.<captain_domain>/api/dex/callback


```yaml
captain_domain: <yournamesgoeshere>.glueops.rocks
externalDns:
  aws_accessKey: XXXXXXXXXXXXXXXXXXXXXXXXXX
  aws_secretKey: XXXXXXXXXXXXXXXXXXXXXXXXXX
  aws_region: us-west-2
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
      hosts: ["argocd.<yournamesgoeshere>.glueops.rocks"]
      tls: 
        - 
          hosts: 
            - argocd.<yournamesgoeshere>.glueops.rocks
          secretName: argocd-tls
    config:
      url: "https://argocd.<yournamesgoeshere>.glueops.rocks"
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
