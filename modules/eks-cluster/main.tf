resource "aws_cloudwatch_log_group" "default" {
  count             = length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cluster_log_retention_period
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  tags              = var.tags
  log_group_class   = var.cloudwatch_log_group_class
}

resource "aws_eks_cluster" "default" {
  count                         = var.create_eks_cluster ? 1 : 0
  name                          = var.eks_cluster_name
  tags                          = var.tags
  role_arn                      = local.eks_service_role_arn
  version                       = var.kubernetes_version
  enabled_cluster_log_types     = var.enabled_cluster_log_types
  bootstrap_self_managed_addons = var.enable_bootstrap_self_managed_addons

  access_config {
    authentication_mode                         = var.access_config.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.access_config.bootstrap_cluster_creator_admin_permissions
  }

  vpc_config {
    security_group_ids      = var.associated_security_group_ids
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  dynamic "kubernetes_network_config" {
    for_each = var.kubernetes_network_ipv6 ? [] : var.service_ipv4_cidr
    content {
      service_ipv4_cidr = kubernetes_network_config.value
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = var.kubernetes_network_ipv6 ? [true] : []
    content {
      ip_family = "ipv6"
    }
  }
  dynamic "encryption_config" {

    for_each = var.cluster_encryption_config_enabled ? [local.cluster_encryption_config] : []
    content {
      resources = encryption_config.value.resources
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
    }
  }


  lifecycle {

    ignore_changes = [access_config[0].bootstrap_cluster_creator_admin_permissions]
  }


  depends_on = [
    aws_iam_role.default,
    aws_iam_role_policy_attachment.cluster_elb_service_role,
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_service_policy,
    aws_kms_alias.cluster,
    aws_cloudwatch_log_group.default,
    var.associated_security_group_ids,
    var.subnet_ids,
  ]
}



#####################################################
## KMS
#####################################################

module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.0" // use the latest version from registry.
  // count                   = var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? 1 : 0
  enabled                 = var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? 1 : 0
  deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  alias                   = var.alias
  tags                    = module.tags.tags
  policy                  = var.cluster_encryption_config_kms_key_policy
}

#####################################################
## OIDC Provider
#####################################################

resource "aws_iam_openid_connect_provider" "default" {
  count = var.oidc_provider_enabled ? 1 : 0
  url   = aws_eks_cluster.default[0].identity[0].oidc[0].issuer
  tags  = module.label.tags

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [(data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint)]
}

######################################################
## EKS Add-ons
######################################################

resource "aws_eks_addon" "cluster" {
  for_each = { for x in var.addons : x.addon_name => addon }

  cluster_name                = aws_eks_cluster.default[0].name
  addon_name                  = each.key
  addon_version               = try(each.value.addon_version, null)
  configuration_values        = try(each.value.configuration_values, null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", try(replace(each.value.resolve_conflicts, "PRESERVE", "NONE"), null))
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", lookup(each.value, "resolve_conflicts", null))
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  tags = var.tags

  depends_on = [
    aws_eks_cluster.default,
    aws_iam_openid_connect_provider.default,
  ]

  timeouts {
    create = each.value.create_timeout
    update = each.value.update_timeout
    delete = each.value.delete_timeout
  }
}
