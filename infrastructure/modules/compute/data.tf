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


# ------------------------------------------------------------------------------
# Karpenter Controller IAM Policy Document (Fine-Grained PoLP & Consolidated < 6KB)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "karpenter_controller" {
  #checkov:skip=CKV_AWS_356: EC2 Describe*, Pricing, and IAM ListInstanceProfiles actions do not support resource-level permissions and strictly require wildcard '*' resources.
  #checkov:skip=CKV_AWS_108: EC2 Describe and Pricing APIs do not support resource-level permissions. SSM reading is explicitly scoped to official AWS public service parameters.

  # Allow launching instances and fleets with scoped resource constraints
  statement {
    sid    = "EC2RunInstancesScoped"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}::image/*",
      "arn:aws:ec2:${data.aws_region.current.name}::snapshot/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:security-group/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:subnet/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:capacity-reservation/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:launch-template/*",
    ]
  }

  # Scoped creation of EC2 resources tagged for this cluster
  statement {
    sid    = "EC2CreateTaggedResources"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:*:fleet/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:volume/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:network-interface/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:launch-template/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:spot-instances-request/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:capacity-reservation/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }
  }

  # Allow tag creation during resource creation and management
  statement {
    sid     = "EC2CreateTagsScoped"
    effect  = "Allow"
    actions = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:*:fleet/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:volume/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:network-interface/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:launch-template/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:spot-instances-request/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  # Allow terminating instances and launch templates owned by Karpenter
  statement {
    sid    = "EC2ResourceDeletion"
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.name}:*:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  # Regional read actions for EC2 instance types, pricing, and topology discovery
  statement {
    sid    = "EC2ReadOnlyDiscovery"
    effect = "Allow"
    actions = [
      "ec2:DescribeCapacityReservations",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
    ]
    resources = ["*"]
  }

  # Read SSM parameters for official EKS optimized AMIs
  statement {
    sid    = "AllowSSMReadActions"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}::parameter/aws/service/*",
    ]
  }

  # Allow querying global EC2 instance pricing data
  statement {
    sid       = "AllowPricingReadActions"
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  # Allow passing node IAM role to EC2 instances launched by Karpenter
  statement {
    sid       = "IAMPassRoleToEC2"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Instance Profile management permissions required for EC2NodeClass
  statement {
    sid    = "InstanceProfileManagement"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*",
    ]
  }

  # Allow listing instance profiles across the account for EC2NodeClass evaluation
  statement {
    sid       = "IAMListProfiles"
    effect    = "Allow"
    actions   = ["iam:ListInstanceProfiles"]
    resources = ["*"]
  }

  # Allow EKS cluster endpoint discovery
  statement {
    sid     = "EKSClusterDescribe"
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}",
    ]
  }

  # SQS Interruption Queue permissions (populated once SQS queue is provisioned)
  statement {
    sid    = "SQSInterruptionQueue"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [var.karpenter_interruption_queue_arn]
  }
}