
variable "kubernetes_cluster_configurations" {}
module "captain" {
  source         = "git::https://github.com/GlueOps/terraform-module-cloud-aws-kubernetes-cluster"
  vpc_cidr_block = var.kubernetes_cluster_configurations.vpc_cidr_block
  region         = var.kubernetes_cluster_configurations.region
  eks_node_group = var.kubernetes_cluster_configurations.eks_node_group
}