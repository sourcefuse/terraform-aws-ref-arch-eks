################################################################
## shared
################################################################
variable "namespace" {
  description = "Namespace for the resources."
  default     = "refarch-devops"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]

}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

#######################################################
## eks / kubernetes / helm
#######################################################
variable "csi_driver_enabled" {
  default = true
}

variable "kubernetes_version" {
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
  type        = string

  default = "1.28"
}

variable "local_exec_interpreter" {
  description = "shell to use for local_exec"
  type        = list(string)
  default     = ["/bin/sh", "-c"]
}

variable "oidc_provider_enabled" {
  description = "Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using `kiam` or `kube2iam`. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
  type        = bool
  default     = true
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

variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
  type        = list(string)

  default = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number

  default = 2
}

variable "min_size" {
  description = "The minimum size of the AutoScaling Group."
  type        = number

  default = 2
}

variable "max_size" {
  description = "The maximum size of the AutoScaling Group."
  type        = number

  default = 4
}

variable "kubernetes_labels" {
  description = "Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default     = {}
}

#######################################################
## data lookups
#######################################################
variable "route_53_zone" {
  type        = string
  description = "Route 53 domain to generate an ACM request for and to create A records against, i.e. sfrefarch.com. A wildcard subject alternative name is generated with the certificate."
}


## ingress
variable "ingress_namespace_name" {
  type        = string
  default     = "ingress-nginx"
  description = "Namespace name"
}

variable "health_check_image" {
  default     = "nginx:alpine"
  description = "Image version for Nginx"
  type        = string
}

variable "health_check_domains" {
  type        = list(string)
  description = "List of A record domains to create for the health check service"
}

variable "environment" {
  type        = string
  default     = null
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'"
}

variable "name" {
  type        = string
  default     = null
  description = <<-EOT
    ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.
    This is the only ID element not also included as a `tag`.
    The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input.
    EOT
}

variable "kubernetes_namespace" {
  description = "Default k8s namespace to create"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).
    Neither the tag keys nor the tag values will be modified by this module.
    EOT
}
