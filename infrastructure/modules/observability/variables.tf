# ------------------------------------------------------------------------------
# Observability Module Input Variables
# ------------------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster used for resource naming and IAM scoping"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region where observability resources are provisioned"
}

variable "log_retention_in_days" {
  type        = number
  description = "Number of days to retain application and cluster logs in CloudWatch"
}