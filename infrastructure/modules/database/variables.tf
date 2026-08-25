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