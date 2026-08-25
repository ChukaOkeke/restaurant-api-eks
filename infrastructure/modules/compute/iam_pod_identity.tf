# ==============================================================================
# PLATFORM CONTROLLERS IAM ROLES & EKS POD IDENTITY ASSOCIATIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. AWS Load Balancer Controller IAM Role & Pod Identity
# ------------------------------------------------------------------------------
# Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "aws_lbc" {
  name        = "${var.environment}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.response_body
}

# Create AWS Load Balancer Controller IAM Role
resource "aws_iam_role" "aws_lbc" {
  name               = "restaurant-api-${var.environment}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name = "restaurant-api-${var.environment}-aws-lbc-role"
  }
}

# Associate Load Balanacer Controller IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}


# ------------------------------------------------------------------------------
# 2. Karpenter Controller IAM Role & Pod Identity
# ------------------------------------------------------------------------------
resource "aws_iam_role" "karpenter_controller" {
  name               = "restaurant-api-${var.environment}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name = "restaurant-api-${var.environment}-karpenter-controller-role"
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "restaurant-api-${var.environment}-karpenter-controller-policy"
  description = "Allows Karpenter controller to discover and provision EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateFleet", "ec2:RunInstances", "ec2:CreateLaunchTemplate", "ec2:DeleteLaunchTemplate", "ec2:Describe*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.node_group.arn
      }
    ]
  })

  tags = {
    Name = "restaurant-api-${var.environment}-karpenter-controller-policy"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  policy_arn = aws_iam_policy.karpenter_controller.arn
  role       = aws_iam_role.karpenter_controller.name
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn
}


# ------------------------------------------------------------------------------
# 3. External Secrets Operator (ESO) IAM Role & Pod Identity
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eso" {
  name               = "restaurant-api-${var.environment}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name = "restaurant-api-${var.environment}-eso-role"
  }
}

resource "aws_iam_policy" "eso" {
  name = "restaurant-api-${var.environment}-eso-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [var.app_secret_arn, "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:restaurant-api-*"]
    }]
  })

  tags = {
    Name = "restaurant-api-${var.environment}-eso-policy"
  }
}

resource "aws_iam_role_policy_attachment" "eso" {
  policy_arn = aws_iam_policy.eso.arn
  role       = aws_iam_role.eso.name
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "external-secrets"
  service_account = "external-secrets-sa"
  role_arn        = aws_iam_role.eso.arn
}


# ------------------------------------------------------------------------------
# 4. ADOT Collector IAM Role & Pod Identity
# ------------------------------------------------------------------------------
resource "aws_iam_role" "adot" {
  name               = "restaurant-api-${var.environment}-adot-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name = "restaurant-api-${var.environment}-adot-role"
  }
}

resource "aws_iam_role_policy_attachment" "adot_prometheus" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  role       = aws_iam_role.adot.name
}

resource "aws_iam_role_policy_attachment" "adot_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.adot.name
}

resource "aws_eks_pod_identity_association" "adot" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "monitoring"
  service_account = "adot-collector-sa"
  role_arn        = aws_iam_role.adot.arn
}


# ------------------------------------------------------------------------------
# 5. OpenCost IAM Role & Pod Identity
# ------------------------------------------------------------------------------
resource "aws_iam_role" "opencost" {
  name               = "restaurant-api-${var.environment}-opencost-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name = "restaurant-api-${var.environment}-opencost-role"
  }
}

resource "aws_iam_policy" "opencost" {
  name = "restaurant-api-${var.environment}-opencost-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ce:GetCostAndUsage", "ce:GetDimensionValues", "ec2:DescribePricing"]
      Resource = "*"
    }]
  })

  tags = {
    Name = "restaurant-api-${var.environment}-opencost-policy"
  }
}

resource "aws_iam_role_policy_attachment" "opencost" {
  policy_arn = aws_iam_policy.opencost.arn
  role       = aws_iam_role.opencost.name
}

resource "aws_eks_pod_identity_association" "opencost" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "opencost"
  service_account = "opencost-sa"
  role_arn        = aws_iam_role.opencost.arn
}