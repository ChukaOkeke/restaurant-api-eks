# ==============================================================================
# ENDPOINTS-SG MODULE INPUT VARIABLES
# ==============================================================================

variable "environment" {
  description = "Target deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the primary VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where VPC endpoints will attach"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for S3 Gateway Endpoint routing"
  type        = list(string)
}

variable "db_port" {
  description = "The network port for the RDS database"
  type        = number
  default     = 5432
}