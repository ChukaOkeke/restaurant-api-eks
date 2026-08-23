# ==============================================================================
# SECURITY MODULE OUTPUT VALUES
# Exports secret details and IAM ARNs for downstream execution
# ==============================================================================

output "app_secret_arn" {
  description = "ARN of the Secrets Manager Application secrets container"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "app_secret_name" {
  description = "Name of the Secrets Manager Application secrets container"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC execution role"
  value       = aws_iam_role.github_actions.arn
}