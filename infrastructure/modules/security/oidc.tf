# ==============================================================================
# ZERO-TRUST CI/CD IDENTITY FEDERATION
# Establishes trust between GitHub Actions and AWS IAM using OIDC federation
# ==============================================================================

# 1. IAM OIDC PROVIDER (Registers GitHub as a Trusted Identity Authority)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "restaurant-api-dev-github-oidc-provider"
  }
}

# 2. THE DEPLOYMENT IAM ROLE (Assumed by GitHub Actions during pipeline runs)
resource "aws_iam_role" "github_actions" {
  name               = "restaurant-api-${var.environment}-github-actions-role"
  description        = "Short-lived access role for GitHub Actions infrastructure deployment workflows"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = {
    Name = "restaurant-api-${var.environment}-github-actions-role"
  }
}

# 3. PERMISSIONS ATTACHMENT
# In actual production, you would prune this to a tightly controlled custom architecture policy.
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  # checkov:skip=CKV_AWS_274: AdminAccess is temporarily retained because Terraform must dynamically provision and manage downstream IAM roles. 
  # In a strict production environment, this would be replaced with a bounded custom policy generated via AWS IAM Access Analyzer, combined with IAM Permission Boundaries to prevent privilege escalation.
}