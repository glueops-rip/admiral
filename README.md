# admiral

## Overview

This Admiral repository will guide you on creating a captain (kubernetes cluster). 

Prerequisites:
- https://github.com/GlueOps/terraform-module-cloud-multy-prerequisites or have a file provided to you with all the outputs from this module


You will need to follow these steps in this order:

1) Create the kubernetes infra for the desired clouder providerss
3) Deploying the GlueOps-Platform onto the kubernetes cluster
4) Intialize/Unseal Vault
5) Configure Vault

Once you complete steps 1-5 you will have a captain that you can deploy your apps onto.

### Deploying your cluster

**IMPORTANT: You can only use 1 Cloud Provider**

| Cloud Providers                                                                                   |
|---------------------------------------------------------------------------------------------------|
| [Google Cloud Platform](https://github.com/GlueOps/terraform-module-cloud-gcp-kubernetes-cluster) |
| [Amazon Web Services](https://github.com/GlueOps/terraform-module-cloud-aws-kubernetes-cluster)   |

### Deploying ArgoCD

https://github.com/GlueOps/argocd-install-docs/

### Deploying the GlueOps Platform

https://github.com/GlueOps/docs-glueops-platform/

### Vault Setup

#### Intialize Vault

https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization

#### Configure Vault

https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration

## Cheat Sheet

### Using the Cluster

- Service Locations
  - **ArgoCD** - `argocd.<captain_domain>`
  - **Vault** - `vault.<captain_domain>`
  - **Grafana** - `grafana.<captain_domain>`
- Accessing Services
  - GitHub OAuth - to confirm OAuth access was configured correctly
    - **ArgoCD** - Click `LOGIN VIA GITHUB SSO` and grant access to the relevant organization(s), which were configured in the `platform.yaml` at `dex.github.orgs`
    - **Vault**  - Click on `oidc` and then type in `reader` or `editor` depending on what role you want to use
    - **Grafana** - Click `Signin with GitHub SSO` and grant access to the relevant organization(s), which were configured in the `platform.yaml` at `dex.github.orgs`

