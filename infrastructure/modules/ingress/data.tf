# ==============================================================================
# Route 53 Hosted Zone Data Source
# ==============================================================================
# Fetches the pre-existing public hosted zone for domain validation & DNS records
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

# ==============================================================================
# Managed CloudFront Security Headers Policy
# ==============================================================================
# AWS-managed policy enforcing baseline HTTP security response headers (HSTS, Frame Options, etc.)
data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}