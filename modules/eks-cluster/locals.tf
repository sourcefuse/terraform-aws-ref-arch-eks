locals {
  create_eks_service_role = var.create_eks_service_role

  eks_service_role_arn = local.create_eks_service_role ? aws_iam_role.default[0].arn : var.eks_cluster_service_role_arn

  cluster_security_group_id = aws_eks_cluster.default[0].vpc_config[0].cluster_security_group_id

  managed_security_group_rules_enabled = var.managed_security_group_rules_enabled


  cluster_encryption_config = {
    resources = var.cluster_encryption_config_resources

    provider_key_arn = var.cluster_encryption_config_kms_key_id == "" ? module.kms.arn : var.cluster_encryption_config_kms_key_id /// kms module
  }
}
