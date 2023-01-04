# admiral

## Overview

This admiral repo lets you orchestrate the deployment and management of a captain cluster with all the services. When running the `terraform`,`helm`, and other CLI commands mentioned in this `README.md`, please assume you are a level above **this** folder. For example, the `-chdir` flag means running the terraform within a particular folder, and the `-state` lets you save it somewhere else. The ideal way to look at this `admiral` repository is that it is a software package. Right now, it's a series of git repositories CLI commands, but we plan to automate this further to where we have a single API call to do all this automation for you.

### Deploying your cluster

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

Example `captain_configuration.tfvars`:

```hcl
kubernetes_cluster_configurations = {
  network_ranges = {
    "kubernetes_pods" : "10.65.0.0/16",
    "kubernetes_services" : "10.64.224.0/20",
    "kubernetes_nodes" : "10.64.64.0/23"
  }
  project_id = "glueops-test-1"
  region     = "us-central1"
}


vault_configurations = {
  backends = [
    {
      github_organization = "GlueOps"
      auth_mount_path     = "glueops/github"
      tune = [{
        allowed_response_headers     = []
        audit_non_hmac_request_keys  = []
        audit_non_hmac_response_keys = []
        default_lease_ttl            = "768h"
        listing_visibility           = "hidden"
        max_lease_ttl                = "768h"
        passthrough_request_headers  = []
        token_type                   = "default-service"
      }]
    },
    {
      github_organization = "glueops-rocks"
      auth_mount_path     = "github"
      tune = [{
        allowed_response_headers     = []
        audit_non_hmac_request_keys  = []
        audit_non_hmac_response_keys = []
        default_lease_ttl            = "768h"
        listing_visibility           = "unauth"
        max_lease_ttl                = "768h"
        passthrough_request_headers  = []
        token_type                   = "default-service"
      }]
    }
  ]
  org_team_policy_mapping = [
    {
      auth_mount_path = "glueops/github"
      github_team     = "vault_super_admins"
      policy          = <<EOT
                          path "*" {
                          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
                          }
                          EOT

    },
    {
      auth_mount_path = "github"
      github_team     = "developers"
      policy          = <<EOF
                          path "secret/*" {
                            capabilities = ["create", "read", "update", "delete", "list"]
                          }

                          path "/cubbyhole/*" {
                            capabilities = ["deny"]
                          }
                          EOF
    }
  ]
}
```
