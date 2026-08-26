# ==============================================================================
# Input Variables (Child Module - No Default Values)
# ==============================================================================

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, staging, prod)"
}

variable "domain_name" {
  type        = string
  description = "Apex domain name registered in Route 53 (e.g., asgardcuisines.link)"
}

variable "backend_domain_name" {
  type        = string
  description = "Target backend domain endpoint for CloudFront dynamic routing"
}

variable "static_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket hosting static media assets"
}

variable "static_bucket_id" {
  type        = string
  description = "Bucket ID / Name of the static assets S3 bucket"
}

variable "static_bucket_regional_domain_name" {
  type        = string
  description = "Regional domain name of the static assets S3 bucket for origin target"
}