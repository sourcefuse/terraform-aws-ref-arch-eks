variable "region" {
  type        = string
  description = "AWS region"
}

#######################################################
## eks / kubernetes / helm
#######################################################
variable "kubernetes_version" {
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
  type        = string
  default     = "1.25"
}

variable "enabled_cluster_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
  type        = list(string)

  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "cluster_log_retention_period" {
  description = "Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html."
  type        = number
  default     = 0
}

# variable "map_additional_aws_accounts" {
#   description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap"
#   type        = list(string)
#   default     = []
# }

## iam

# variable "map_additional_iam_users" {
#   type = list(object({
#     userarn  = string
#     username = string
#     groups   = list(string)
#   }))
#   description = "Additional IAM users to add to `config-map-aws-auth` ConfigMap"
#   default     = []
# }

variable "oidc_provider_enabled" {
  description = "Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using `kiam` or `kube2iam`. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
  type        = bool
  default     = true
}

variable "admin_principal" {
  description = "list of arns of IAM users/roles to be allowed to assume the eks-admin role. Default behaviour it to allow all users in the same AWS account as the caller"
  type        = list(string)
  default     = null
}

variable "public_access_cidrs" {
  description = "Specify the cidr blocks which will be able to access the eks public api endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

## workers
# variable "local_exec_interpreter" {
#   description = "shell to use for local_exec"
#   type        = list(string)
#   default     = ["/bin/sh", "-c"]
# }

variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
  type        = list(string)
}

variable "kubernetes_labels" {
  description = "Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default     = {}
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "max_size" {
  description = "The maximum size of the AutoScaling Group"
  type        = number
}

variable "min_size" {
  description = "The minimum size of the AutoScaling Group"
  type        = number
}

// TODO: To be enabled when core apps module / CSI driver is added back
## csi secrets driver
variable "csi_driver_enabled" {
  description = "The Secrets Store CSI Driver secrets-store.csi.k8s.io allows Kubernetes to mount multiple secrets, keys, and certs stored in enterprise-grade external secrets stores into their pods as a volume."
  type        = bool
  default     = false
}

## cluster configuration
variable "cluster_encryption_config_enabled" {
  description = "Set to `true` to enable Cluster Encryption Configuration"
  type        = bool
  default     = true
}

variable "cluster_encryption_config_kms_key_id" {
  description = "KMS Key ID to use for cluster encryption config"
  type        = string
  default     = ""
}

variable "cluster_encryption_config_kms_key_enable_key_rotation" {
  description = "Cluster Encryption Config KMS Key Resource argument - enable kms key rotation"
  type        = bool
  default     = true
}

variable "cluster_encryption_config_kms_key_deletion_window_in_days" {
  description = "Cluster Encryption Config KMS Key Resource argument - key deletion windows in days post destruction"
  type        = number
  default     = 10
}

variable "cluster_encryption_config_kms_key_policy" {
  description = "Cluster Encryption Config KMS Key Resource argument - key policy"
  type        = string
  default     = null
}

variable "cluster_encryption_config_resources" {
  description = "Cluster Encryption Config Resources to encrypt, e.g. ['secrets']"
  type        = list(any)
  default     = ["secrets"]
}

variable "addons" {
  type = list(object({
    addon_name                  = string
    addon_version               = optional(string, null)
    configuration_values        = optional(string, null)
    resolve_conflicts_on_create = optional(string, null)
    resolve_conflicts_on_update = optional(string, null)
    service_account_role_arn    = optional(string, null)
    create_timeout              = optional(string, null)
    update_timeout              = optional(string, null)
    delete_timeout              = optional(string, null)
  }))
  description = "Manages [`aws_eks_addon`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) resources"
  default     = []
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace for selection"
}

variable "access_config" {
  type = object({
    authentication_mode                         = optional(string, "API")
    bootstrap_cluster_creator_admin_permissions = optional(bool, false)
  })
  description = "Access configuration for the EKS cluster."
  default     = {}
  nullable    = false

  validation {
    condition     = !contains(["CONFIG_MAP"], var.access_config.authentication_mode)
    error_message = "The CONFIG_MAP authentication_mode is not supported."
  }
}

variable "access_entry_map" {
  type = map(object({
    # key is principal_arn
    user_name = optional(string)
    # Cannot assign "system:*" groups to IAM users, use ClusterAdmin and Admin instead
    kubernetes_groups = optional(list(string), [])
    type              = optional(string, "STANDARD")
    access_policy_associations = optional(map(object({
      # key is policy_arn or policy_name
      access_scope = optional(object({
        type       = optional(string, "cluster")
        namespaces = optional(list(string))
      }), {}) # access_scope
    })), {})  # access_policy_associations
  }))         # access_entry_map
  description = <<-EOT
    Map of IAM Principal ARNs to access configuration.
    Preferred over other inputs as this configuration remains stable
    when elements are added or removed, but it requires that the Principal ARNs
    and Policy ARNs are known at plan time.
    Can be used along with other `access_*` inputs, but do not duplicate entries.
    Map `access_policy_associations` keys are policy ARNs, policy
    full name (AmazonEKSViewPolicy), or short name (View).
    It is recommended to use the default `user_name` because the default includes
    IAM role or user name and the session name for assumed roles.
    As a special case in support of backwards compatibility, membership in the
    `system:masters` group is is translated to an association with the ClusterAdmin policy.
    In all other cases, including any `system:*` group in `kubernetes_groups` is prohibited.
    EOT
  default     = {}
  nullable    = false
}

#######################################################
## data lookups
#######################################################
# variable "vpc_id" {
#   type        = string
#   description = "VPC ID"
# }

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

# auth variables
# variable "apply_config_map_aws_auth" {
#   type        = bool
#   default     = true
#   description = "Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster"
# }

# variable "kube_data_auth_enabled" {
#   type        = bool
#   default     = true
#   description = <<-EOT
#     If `true`, use an `aws_eks_cluster_auth` data source to authenticate to the EKS cluster.
#     Disabled by `kubeconfig_path_enabled` or `kube_exec_auth_enabled`.
#     EOT
# }


# variable "kube_exec_auth_enabled" {
#   type        = bool
#   default     = false
#   description = <<-EOT
#     If `true`, use the Kubernetes provider `exec` feature to execute `aws eks get-token` to authenticate to the EKS cluster.
#     Disabled by `kubeconfig_path_enabled`, overrides `kube_data_auth_enabled`.
#     EOT
# }

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to allow access to the cluster.
    EOT
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IPv4 CIDRs to allow access to the cluster.
    The length of this list must be known at "plan" time.
    EOT
}

variable "create_fargate_profile" {
  type        = bool
  default     = false
  description = "Whether to create EKS Fargate profile"
}

variable "create_node_group" {
  type        = bool
  default     = false
  description = "Whether to create EKS Node Group"
}

# TODO:  enable after testing
# variable "create_worker_nodes" {
#   type        = bool
#   default     = false
#   description = "Whether to create unmanaged Worker nodes"
# }

# variable "worker_node_data" {
#   type = object({
#     instance_type                          = string
#     health_check_type                      = optional(string, "EC2")
#     min_size                               = number
#     max_size                               = number
#     wait_for_capacity_timeout              = optional(string, "10m")
#     autoscaling_policies_enabled           = optional(bool, false)
#     cpu_utilization_high_threshold_percent = optional(number, 90)
#     cpu_utilization_low_threshold_percent  = optional(number, 10)
#   })
#   default = {
#     instance_type     = "t3.small"
#     health_check_type = "EC2"
#     min_size          = 2
#     max_size          = 2
#   }
#   description = "EKS Worker node data"
# }

variable "launch_template_id" {
  type        = list(string)
  default     = []
  description = "The ID (not name) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image ID."
  validation {
    condition = (
      length(var.launch_template_id) < 2
    )
    error_message = "You may not specify more than one `launch_template_id`."
  }
}

variable "launch_template_version" {
  type        = list(string)
  default     = []
  description = "The version of the specified launch template to use. Defaults to latest version."
  validation {
    condition = (
      length(var.launch_template_version) < 2
    )
    error_message = "You may not specify more than one `launch_template_version`."
  }
}

variable "ami_image_id" {
  type        = list(string)
  default     = []
  description = "AMI to use. Ignored if `launch_template_id` is supplied."
  validation {
    condition = (
      length(var.ami_image_id) < 2
    )
    error_message = "You may not specify more than one `ami_image_id`."
  }
}

variable "ami_release_version" {
  type        = list(string)
  default     = []
  description = "EKS AMI version to use, e.g. For AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or  for Windows \"2023.02.14\". For AL2, bottlerocket and Windows, it defaults to latest version for Kubernetes version."
  validation {
    condition = (
      length(var.ami_release_version) == 0 ? true : length(regexall("(^\\d+\\.\\d+\\.\\d+-[\\da-z]+$)|(^\\d+\\.\\d+\\.\\d+$)", var.ami_release_version[0])) == 1
    )
    error_message = "Var ami_release_version, if supplied, must be like for AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or for Windows \"2023.02.14\"."
  }
}

variable "capacity_type" {
  type        = string
  default     = null
  description = <<-EOT
    Type of capacity associated with the EKS Node Group. Valid values: "ON_DEMAND", "SPOT", or `null`.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  validation {
    condition     = var.capacity_type == null ? true : contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either `null`, \"ON_DEMAND\", or \"SPOT\"."
  }
}

variable "ami_type" {
  type        = string
  description = <<-EOT
    Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64, WINDOWS_CORE_2022_x86_64, WINDOWS_FULL_2022_x86_64`.
    EOT
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", or \"CUSTOM\"."
  }
}
