provider "aws" {
  region  = var.region
  profile = var.profile
}

terraform {
  required_providers {
    null = {
      version = "3.1.0"
      source  = "hashicorp/null"
    }
  }
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
