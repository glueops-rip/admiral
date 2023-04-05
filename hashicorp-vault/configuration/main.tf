variable "vault_configurations" {}
module "initialize_vault_cluster" {
  source                   = "git::https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration.git?ref=v0.4.0"
  captain_domain           = var.vault_configurations.captain_domain
  oidc_client_secret       = var.vault_configurations.oidc_client_secret
  org_team_policy_mappings = var.vault_configurations.org_team_policy_mappings
}
