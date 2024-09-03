#####################################################
## Cloudwatch
#####################################################

variable "cloudwatch_log_group_kms_key_id" {
  type        = string
  description = "If provided, the KMS Key ID to use to encrypt AWS CloudWatch logs"
  default     = null
}

variable "cloudwatch_log_group_class" {
  type        = string
  description = "Specified the log class of the log group. Possible values are: `STANDARD` or `INFREQUENT_ACCESS`"
  default     = null
}

variable "cluster_log_retention_period" {
  type        = number
  description = "Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html."
  default     = 0
}

variable "cloudwatch_log_group_name" { //
  type        = string
  description = "Name for Logging group "
  default     = ""
}

variable "tags" { //
  type        = map(string)
  description = "Tags for AWS resources"
}


#####################################################
## Cluster
#####################################################

variable "create_eks_cluster" { //
  type        = string
  description = "Flag for create eks cluster"
}

variable "eks_cluster_name" { //
  type        = string
  description = "Name to be used for EKS Cluster"
}


variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
  default     = []
}

variable "kubernetes_version" {
  type        = string
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
  default     = "1.21"
}

variable "enable_bootstrap_self_managed_addons" {
  type        = bool
  description = "This is to enable bootstrap self managed addons"
}

variable "access_config" {
  type = object({
    authentication_mode                         = optional(string, "API")
    bootstrap_cluster_creator_admin_permissions = optional(bool, false)
  })
  description = "Access configuration for the EKS cluster."
  default     = {}
  nullable    = false
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to launch the cluster in"
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the cluster with.
    These security groups will not be modified.
    EOT
}

variable "endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false"
  default     = false
}

variable "endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
  default     = true
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0."
  default     = ["0.0.0.0/0"]
}

variable "kubernetes_network_ipv6" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
  default     = false
}

variable "service_ipv4_cidr" {
  type        = string
  description = <<-EOT
    The CIDR block to assign Kubernetes service IP addresses from.
    You can only specify a custom CIDR block when you create a cluster, changing this value will force a new cluster to be created.
    EOT
  default     = null
}

variable "cluster_encryption_config_resources" {
  type        = list(any)
  description = "Cluster Encryption Config Resources to encrypt, e.g. ['secrets']"
  default     = ["secrets"]
}

variable "cluster_encryption_config_kms_key_id" {
  type        = string
  description = "KMS Key ID to use for cluster encryption config"
  default     = ""
}

variable "cluster_encryption_config_enabled" {
  type        = bool
  description = "Set to `true` to enable Cluster Encryption Configuration"
  default     = true
}

#####################################################
## Security-group
#####################################################

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

variable "custom_ingress_rules" {
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
  }))
  default     = []
  description = <<-EOT
    A List of Objects, which are custom security group rules that
    EOT
}

#####################################################
## KMS
#####################################################

variable "cluster_encryption_config_kms_key_deletion_window_in_days" {
  type        = number
  description = "Cluster Encryption Config KMS Key Resource argument - key deletion windows in days post destruction"
  default     = 10
}

variable "cluster_encryption_config_kms_key_policy" {
  type        = string
  description = "Cluster Encryption Config KMS Key Resource argument - key policy"
  default     = null
}

variable "alias" {
  type        = string
  description = "Alias name for KMS key eg. alias/{NAME}"
  default     = null
}

variable "cluster_encryption_config_resources" {
  type        = list(any)
  description = "Cluster Encryption Config Resources to encrypt, e.g. ['secrets']"
  default     = ["secrets"]
}



#####################################################
## IAM
#####################################################

variable "iam_role_name" {
  type        = string
  description = "Name for IAM role used for cluster"
  default     = "default-role"
}

variable "permissions_boundary" {
  type        = string
  description = "If provided, all IAM roles will be created with this permissions boundary attached"
  default     = null
}

#####################################################
## EKS-Addon
#####################################################

variable "addons" {
  type = list(object({
    addon_name           = string
    addon_version        = optional(string, null)
    configuration_values = optional(string, null)
    # resolve_conflicts is deprecated, but we keep it for backwards compatibility
    # and because if not declared, Terraform will silently ignore it.
    resolve_conflicts           = optional(string, null)
    resolve_conflicts_on_create = optional(string, null)
    resolve_conflicts_on_update = optional(string, null)
    service_account_role_arn    = optional(string, null)
    create_timeout              = optional(string, null)
    update_timeout              = optional(string, null)
    delete_timeout              = optional(string, null)
  }))
  description = <<-EOT
    Manages [`aws_eks_addon`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) resources.
    Note: `resolve_conflicts` is deprecated. If `resolve_conflicts` is set and
    `resolve_conflicts_on_create` or `resolve_conflicts_on_update` is not set,
    `resolve_conflicts` will be used instead. If `resolve_conflicts_on_create` is
    not set and `resolve_conflicts` is `PRESERVE`, `resolve_conflicts_on_create`
    will be set to `NONE`.
    EOT
  default     = []
}

variable "oidc_provider_enabled" {
  type        = bool
  description = "Creating OIDC provider helps to create IAM roles to associate with a service account in the cluster"
  default     = false
}
