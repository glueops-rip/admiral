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

See docs for [AWS](https://github.com/GlueOps/terraform-module-cloud-aws-kubernetes-cluster)

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

See docs for [GCP](https://github.com/GlueOps/terraform-module-cloud-gcp-kubernetes-cluster)

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

#### Deploying ArgoCD

- Prepare a argocd.yaml to use for your argocd installation
  
```bash
cp ./admiral/argocd.yaml.tpl argocd.yaml
```

- Read the comments in the file and update the values in the argocd.yaml file.
  - Quick Notes:
    - Replace `<tenant-name-goes-here>` with your tenant/company key. Example: `antoniostacos`
    - Replace `<cluster_env>` with your cluster_environment name. Example: `nonprod`
    - The `clientSecret` that you specify needs to be the same one you use in the `platform.yaml` for ArgoCD. If they do not match you will not be able to login.

- Install ArgoCD

```bash
kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v2.6.6" # You need to install the CRD's that match the version of the app in the helm chart.
helm repo add argo https://argoproj.github.io/argo-helm # Adds the argo helm repository to your local environment
helm install argocd argo/argo-cd --skip-crds --version 5.27.1 -f argocd.yaml --namespace=glueops-core --create-namespace #this command includes --skip-crds but the way the chart works we also have a value we need to set to false so that the CRD's do not work. This value is in the argocd.yaml
```

- Check to see if all ArgoCD pods are in a good state with: 

```bash
kubectl get pods -n glueops-core
```

- Using the command above, ensure that the ArgoCD pods are stable and no additional pods/containers are coming online. If there is a pod that is 1/3 wait until it's 3/3 and has been running for at least a minute. This entire bootstrap can take about 5mins as we are deploying a number of services in HA mode.

#### Deploying the GlueOps Platform

- Prepare a `platform.yaml` to use for the GlueOps Platform installation. 
  - Please reference the `values.yaml` from the [platform chart](https://github.com/GlueOps/platform-helm-chart-platform/tree/v0.1.1)
  - We recommend copying the `values.yaml` and saving it as your `platform.yaml` and then updating values as needed. There are inline comments next to each value.
  - Quick Notes:
    - Replace `<tenant-name-goes-here>` with your tenant/company key. Example: `antoniostacos`
    - Replace `<cluster_env> with your` cluster_environment name. Example: `nonprod`
    - As mentioned above, the ArgoCD's `clientSecret` needs to match the ArgoCD `client_secret` you define within this `platform.yaml`.

```bash
helm repo add glueops-platform https://helm.gpkg.io/platform
helm install glueops-platform glueops-platform/glueops-platform --version 0.1.1 -f platform.yaml --namespace=glueops-core
```

- Check on ArgoCD application status with

```bash
kubectl get applications -n glueops-core
```

**_Notes:_ It can take up to 10 minutes for the services on kubernetes to come up and for DNS to work..**

### Vault Setup

#### Intialize Vault

See docs for [Intializing Vault](https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization)

From the root directory of your repository, initialize vault using the following commands

```bash
terraform -chdir=admiral/hashicorp-vault/init init
export VAULT_SKIP_VERIFY=true && terraform -chdir=admiral/hashicorp-vault/init apply -state=$(pwd)/terraform_states/vault-init.terraform.tfstate
```

#### Configure Vault

See docs for [Configuring Vault](https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration)

```bash
terraform -chdir=admiral/hashicorp-vault/configuration init
export VAULT_SKIP_VERIFY=true && terraform -chdir=admiral/hashicorp-vault/configuration apply -state=$(pwd)/terraform_states/vault-configuration.terraform.tfstate -var-file=$(pwd)/captain_configuration.tfvars
```

## Cheat Sheet

### Using the Cluster

- Service Locations
  - **ArgoCD** - `argocd.{captain_domain from captain.yaml}`
  - **Vault** - `vault.{captain_domain from captain.yaml}`
  - **Grafana** - `grafana.{captain_domain from captain.yaml}`
- Accessing Services
  - GitHub OAuth - to confirm OAuth access was configured correctly
    - **ArgoCD** - Click `LOGIN VIA GITHUB SSO` and grant access to the relevant organization(s), which were configured in the `platform.yaml` at `dex.github.orgs`
    - **Vault**  - [Create a GitHub Personal Access Token](https://github.com/settings/tokens) with permission to `read:org`.  Paste the token into the Vault UI.
    - **Grafana** - Click `Signin with GitHub SSO` and grant access to the relevant organization(s), which were configured in the `platform.yaml` at `dex.github.orgs`
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

### Tips

- To do much of anything, you probably need to authenticate with the K8s cluster. See the Cloud specific Authentication details **_above_**.
- Whenever running terraform against vault you need a connection to vault: `kubectl -n glueops-core-vault port-forward svc/vault-ui 8200:8200`
- When making IaC updates to the Kubernetes cluster itself (ex., new node pools or updating cluster version, VPC peering, etc.) you must authenticate to that cloud provider and those instructions will be in the terraform module that you used to deploy the cluster in the `##### Deployment` section
- Remember all commands in this document assume you are "above" the admiral folder.
