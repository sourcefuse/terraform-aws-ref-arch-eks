resource "aws_iam_role" "default" {
  count = local.create_eks_service_role ? 1 : 0

  name                 = var.iam_role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  tags                 = var.tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = "arn:${data.aws_partition.current[0].partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.default[0].name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_service_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = "arn:${data.aws_partition.current[0].partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.default[0].name
}

resource "aws_iam_policy" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  name   = "${var.iam_role_name}-ServiceRole-policy"
  policy = data.aws_iam_policy_document.cluster_elb_service_role[0].json
}

resource "aws_iam_role_policy_attachment" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = aws_iam_policy.cluster_elb_service_role[0].arn
  role       = aws_iam_role.default[0].name
}
