# ==============================================================================
# DATABASE MODULE OUTPUT VALUES
# ==============================================================================

output "db_instance_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "RDS hostname address"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_master_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret managed natively by RDS"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}