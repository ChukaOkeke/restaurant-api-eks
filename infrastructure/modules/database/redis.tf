# ==============================================================================
# ELASTICACHE REDIS REPLICATION GROUP & SECURITY
# ==============================================================================

# Create a subnet group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "restaurant-api-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "restaurant-api-${var.environment}-redis-subnet-group"
  }
}

# Generate a secure random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Create an Elasticache Redis replication group with multi-AZ and encryption enabled
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "restaurant-api-${var.environment}-redis"
  description                = "Production Redis cache for Restaurant API"
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_clusters
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.redis_sg_id]
  automatic_failover_enabled = true
  multi_az_enabled           = var.multi_az # Multi-AZ disabled in dev/staging environments to optimize infrastructure costs.
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  engine                     = "redis"
  engine_version             = "7.1"

  tags = {
    Name = "restaurant-api-${var.environment}-redis-replication-group"
  }
}