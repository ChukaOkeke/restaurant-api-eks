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

output "redis_primary_endpoint_address" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis primary endpoint address"
}

output "redis_auth_token" {
  value       = random_password.redis_auth_token.result
  description = "Redis authentication token"
}