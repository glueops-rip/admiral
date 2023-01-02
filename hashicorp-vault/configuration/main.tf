variable "vault_configurations" {}
module "initialize_vault_cluster" {
    source = "git::https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration"
    backends = var.vault_configurations.backends
    org_team_policy_mapping = var.vault_configurations.org_team_policy_mapping
}
