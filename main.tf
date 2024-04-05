module "eks_cluster" {
  source  = "cloudposse/eks-cluster/aws"
  version = "4.0.0"

  allowed_security_group_ids = var.allowed_security_group_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  region                     = var.region
  # vpc_id                       = var.vpc_id
  subnet_ids         = var.subnet_ids
  kubernetes_version = var.kubernetes_version
  # local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  public_access_cidrs          = var.public_access_cidrs
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  cluster_encryption_config_enabled                         = var.cluster_encryption_config_enabled
  cluster_encryption_config_kms_key_id                      = var.cluster_encryption_config_kms_key_id
  cluster_encryption_config_kms_key_enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  cluster_encryption_config_kms_key_deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  cluster_encryption_config_kms_key_policy                  = var.cluster_encryption_config_kms_key_policy
  cluster_encryption_config_resources                       = var.cluster_encryption_config_resources

  # map_additional_iam_roles = local.map_additional_iam_roles
  # map_additional_iam_users = var.map_additional_iam_users

  addons            = var.addons
  addons_depends_on = [module.eks_node_group]

  access_entry_map = var.access_entry_map
  access_config    = var.access_config

  # apply_config_map_aws_auth                 = var.apply_config_map_aws_auth
  # kube_data_auth_enabled                    = var.kube_data_auth_enabled
  # kubernetes_config_map_ignore_role_changes = true
  # kube_exec_auth_enabled                    = var.kube_exec_auth_enabled

  context = module.this.context
  tags    = var.tags
}

resource "aws_iam_role" "eks_admin" {
  name               = "${module.eks_cluster.eks_cluster_id}-eks-admin"
  assume_role_policy = data.aws_iam_policy_document.eks_admin_assume_role.json
  inline_policy {
    name   = "${module.eks_cluster.eks_cluster_id}-eks-admin-policy"
    policy = data.aws_iam_policy_document.eks_admin.json
  }
  tags = var.tags
}

module "eks_fargate_profile" {
  source  = "cloudposse/eks-fargate-profile/aws"
  version = "1.3.0"

  enabled = var.create_fargate_profile

  subnet_ids                              = var.subnet_ids
  cluster_name                            = module.eks_cluster.eks_cluster_id
  kubernetes_namespace                    = kubernetes_namespace.default_namespace[0].metadata[0].name
  kubernetes_labels                       = var.kubernetes_labels
  iam_role_kubernetes_namespace_delimiter = "@"

  context = module.this.context

  tags = var.tags
}


resource "kubernetes_namespace" "default_namespace" {
  count = (var.enabled && var.kubernetes_namespace != "kube-system") ? 1 : 0

  metadata {
    name = var.kubernetes_namespace
  }

  depends_on = [
    module.eks_cluster
  ]
}

module "eks_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "2.12.0"

  enabled = var.create_node_group

  subnet_ids                 = var.subnet_ids
  cluster_name               = module.eks_cluster.eks_cluster_id
  instance_types             = var.instance_types
  desired_size               = var.desired_size
  min_size                   = var.min_size
  max_size                   = var.max_size
  kubernetes_labels          = var.kubernetes_labels
  cluster_autoscaler_enabled = true
  ami_type                   = var.ami_type
  capacity_type              = var.capacity_type
  ami_image_id               = var.ami_image_id
  ami_release_version        = var.ami_release_version
  launch_template_id         = var.launch_template_id
  launch_template_version    = var.launch_template_version

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  # module_depends_on = module.eks_cluster.kubernetes_config_map_id

  context = module.this.context

  tags = var.tags
}

# TODO: Enable after fixing CP issue
# module "eks_workers" {
#   source  = "cloudposse/eks-workers/aws"
#   version = "1.0.0"
#   enabled = var.create_worker_nodes

#   instance_type                      = var.worker_node_data.instance_type
#   vpc_id                             = var.vpc_id
#   subnet_ids                         = var.subnet_ids
#   health_check_type                  = var.worker_node_data.health_check_type
#   min_size                           = var.worker_node_data.min_size
#   max_size                           = var.worker_node_data.max_size
#   wait_for_capacity_timeout          = var.worker_node_data.wait_for_capacity_timeout
#   cluster_name                       = module.eks_cluster.eks_cluster_id
#   cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
#   cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
#   cluster_security_group_id          = module.eks_cluster.eks_cluster_managed_security_group_id
#   bootstrap_extra_args               = "--use-max-pods false"
#   kubelet_extra_args                 = "--node-labels=purpose=ci-worker"

#   # Auto-scaling policies and CloudWatch metric alarms
#   autoscaling_policies_enabled           = var.worker_node_data.autoscaling_policies_enabled
#   cpu_utilization_high_threshold_percent = var.worker_node_data.cpu_utilization_high_threshold_percent
#   cpu_utilization_low_threshold_percent  = var.worker_node_data.cpu_utilization_low_threshold_percent
# }


# module "cluster_autoscaler_helm" {
#   source = "git::https://github.com/lablabs/terraform-aws-eks-cluster-autoscaler?ref=v2.0.0"

#   enabled           = true
#   argo_enabled      = false
#   argo_helm_enabled = false

#   irsa_role_name_prefix            = module.eks_cluster.eks_cluster_id
#   cluster_name                     = module.eks_cluster.eks_cluster_id
#   cluster_identity_oidc_issuer     = module.eks_cluster.eks_cluster_identity_oidc_issuer
#   cluster_identity_oidc_issuer_arn = module.eks_cluster.eks_cluster_identity_oidc_issuer_arn

#   values = yamlencode({
#     "image" : {
#       "tag" : "v1.21.2"
#     }
#   })

#   argo_sync_policy = {
#     "automated" : {}
#     "syncOptions" = ["CreateNamespace=true"]
#   }
# }
