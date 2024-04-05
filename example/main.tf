provider "aws" {
  region = var.region
}

module "tags" {
  source      = "sourcefuse/arc-tags/aws"
  version     = "1.2.2"
  environment = var.environment
  project     = "arc"

  extra_tags = {
    Repo = "github.com/sourcefuse/terraform-aws-arc-eks"
  }
}

module "eks_cluster" {
  source = "../"
  # version              = "5.0.5"
  environment          = var.environment
  name                 = var.name
  namespace            = var.namespace
  desired_size         = var.desired_size
  instance_types       = var.instance_types
  kubernetes_namespace = var.kubernetes_namespace
  create_node_group    = true
  max_size             = var.max_size
  min_size             = var.min_size
  subnet_ids           = data.aws_subnets.private.ids
  region               = var.region

  enabled            = true
  kubernetes_version = var.kubernetes_version
  access_entry_map   = local.access_entry_map
  access_config = {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }
  map_additional_iam_roles   = var.map_additional_iam_roles
  allowed_security_group_ids = concat(data.aws_security_groups.eks_sg.ids, data.aws_security_groups.db_sg.ids)
}
