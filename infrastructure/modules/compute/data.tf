# ==============================================================================
# COMPUTE MODULE DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS Pod Identity Trust Policy (Allows pods.eks.amazonaws.com to assume roles)
data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# Datasource: To get default EKS addon version compatible with EKS cluster version
data "aws_eks_addon_version" "pia_default" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = var.cluster_version
}

# Datasource: To get latest EKS addon version compatible with EKS cluster version
data "aws_eks_addon_version" "pia_latest" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# Datasource: Get AWS Load Balancer Controller IAM Policy from aws-load-balancer-controller/ GIT Repo (latest)
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

# Datasource: Fetches the pre-existing public hosted zone for domain validation & DNS records
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}
