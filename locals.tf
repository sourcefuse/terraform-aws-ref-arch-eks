locals {
  admin_principal = var.admin_principal != null ? var.admin_principal : ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:root"]
  #kubernetes_config_map_id = module.eks_cluster.kubernetes_config_map_id

  # ingress_settings = {
  #   "awsVpcID" : data.aws_vpc.vpc.id
  #   "awsRegion" : var.region
  # }

  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking

  #tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.

  #eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  # public_subnets_additional_tags = {
  #   "kubernetes.io/role/elb" : 1
  # }

  # private_subnets_additional_tags = {
  #   "kubernetes.io/role/internal-elb" : 1
  # }

  # aws_csi_secrets_store_provider_installer_manifest_enabled = var.csi_driver_enabled == true ? 1 : 0
  # kubectl_path_documents_docs = [
  #   for file in fileset(path.module, "/manifests/*.yaml") : file
  # ]
}
