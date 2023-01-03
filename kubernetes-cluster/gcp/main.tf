
variable "kubernetes_cluster_configurations" {}
module "captain" {
  source         = "git::https://github.com/GlueOps/terraform-module-cloud-gcp-kubernetes-cluster"
  network_ranges = var.kubernetes_cluster_configurations.network_ranges
  project_id     = var.kubernetes_cluster_configurations.project_id
  region         = var.kubernetes_cluster_configurations.region
}