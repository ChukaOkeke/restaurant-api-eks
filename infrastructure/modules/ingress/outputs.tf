# ==============================================================================
# Module Outputs
# ==============================================================================

output "cloudfront_distribution_id" {
  description = "ID of the primary CloudFront distribution"
  value       = aws_cloudfront_distribution.api_cdn.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api_cdn.domain_name
}

output "acm_certificate_arn" {
  description = "ARN of the edge TLS ACM certificate"
  value       = aws_acm_certificate.api_cert.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the global CloudFront WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}