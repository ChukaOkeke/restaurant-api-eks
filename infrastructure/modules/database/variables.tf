# ==============================================================================
# DATABASE MODULE INPUT VARIABLES
# ==============================================================================

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the RDS subnet group"
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID allowing port 5432 ingress from EKS nodes"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class (Graviton t4g series recommended for cost/performance)"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment (Keep false for dev cost optimization, set true in production)"
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache node instance type"
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Number of cache clusters in the replication group"
}

variable "redis_sg_id" {
  type        = string
  description = "Security Group ID for ElastiCache Redis"
}