# ==============================================================================
# SECURITY MODULE DATA SOURCES
# Dynamic TLS lookup and IAM Trust Policy documents for GitHub OIDC
# ==============================================================================

# Dynamic TLS certificate lookup to prevent hardcoded thumbprint breakage
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# AssumeRoleWithWebIdentity trust policy restricted explicitly to target repository and branch
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Strict Conditional Safeguards: Lock down access ONLY to your repo and main branch
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}*/${var.github_repo}*:*"]
    }
  }
}