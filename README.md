# admiral

### Deploy cluster
See docs in: <https://github.com/GlueOps/terraform-module-cloud-gcp-kubernetes-cluster>

```bash
terraform -chdir=admiral/kubernetes-cluster/gcp init
terraform -chdir=admiral/kubernetes-cluster/gcp apply -state=$(pwd)/terraform_states/kubernetes-cluster.terraform.tfstate -var-file=$(pwd)/glueops_configuration.tfvars
```

### Intialize Vault

See docs in: <https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization>

```bash
terraform -chdir=admiral/hashicorp-vault/init init
terraform -chdir=admiral/hashicorp-vault/init apply -state=$(pwd)/terraform_states/vault-init.terraform.tfstate
```

### Configure Vault

```bash
terraform -chdir=admiral/hashicorp-vault/configuration init
terraform -chdir=admiral/hashicorp-vault/configuration apply -state=$(pwd)/terraform_states/vault-configuration.terraform.tfstate -var-file=$(pwd)/glueops_configuration.tfvars
```

Example `glueops_configuration.tfvars`:

```hcl
kubernetes_cluster_configurations = {
  network_ranges = {
    "kubernetes_pods" : "10.65.0.0/16",
    "kubernetes_services" : "10.64.224.0/20",
    "public_primary" : "10.64.64.0/23"
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
