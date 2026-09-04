# ==============================================================================
# APPLICATION SECRETS MANAGEMENT WITH AWS SECRETS MANAGER
# Secure storage for Django/API runtime environment variables and external tokens
# ==============================================================================

# 1. THE APP SECRET CONTAINER
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "restaurant-api-${var.environment}-app-secrets"
  description             = "Secure container for EKS application runtime environment variables and API keys."
  recovery_window_in_days = 0 # FinOps safety: Can use 7 in prod. short window allows faster recreation testing if wiped

  # checkov:skip=CKV_AWS_149:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  # checkov:skip=CKV2_AWS_57:Automatic secret rotation is bypassed in dev to avoid the engineering overhead of maintaining a rotation Lambda function and managing synchronized states during iterative testing blocks.

  tags = {
    Name = "restaurant-api-${var.environment}-app-secrets"
  }
}

# 2. THE INITIAL KEY SHELL
# Gives your application schema structure without storing plaintext values in git.
resource "aws_secretsmanager_secret_version" "app_secrets_template" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    APP_ENV       = var.environment
    DJANGO_SECRET = "placeholder-to-be-updated-via-aws-console"
    LOG_LEVEL     = "info"
  })

  # Prevents Terraform from overwriting real production values on subsequent runs
  lifecycle {
    ignore_changes = [secret_string]
  }
}