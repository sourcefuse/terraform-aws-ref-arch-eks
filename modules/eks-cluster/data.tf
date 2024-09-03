data "aws_iam_policy_document" "assume_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    sid    = "AllowElasticLoadBalancer"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSubnets"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyCreateLogGroup"
    effect = "Deny"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
}

data "aws_partition" "current" {}

data "tls_certificate" "cluster" {
  count = var.oidc_provider_enabled ? 1 : 0
  url   = one(aws_eks_cluster.default[*].identity[0].oidc[0].issuer)
}
