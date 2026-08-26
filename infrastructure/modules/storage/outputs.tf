# ==============================================================================
# Module Outputs
# ==============================================================================

output "s3_static_bucket_arn" {
  description = "ARN of the static assets S3 bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "s3_static_bucket_id" {
  description = "Name and ID of the static assets S3 bucket"
  value       = aws_s3_bucket.static_assets.id
}

output "s3_bucket_domain_name" {
  description = "Global domain name of the static assets S3 bucket"
  value       = aws_s3_bucket.static_assets.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the static assets S3 bucket used for CloudFront origin targeting"
  value       = aws_s3_bucket.static_assets.bucket_regional_domain_name
}