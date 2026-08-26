# ==============================================================================
# ACM Certificate Request (us-east-1 for CloudFront Edge distribution)
# ==============================================================================
resource "aws_acm_certificate" "api_cert" {
  provider          = aws.us_east_1 # Crucial: Must be instantiated in N. Virginia
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "restaurant-api-${var.environment}-edge-tls-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Route 53 DNS Validation Records
# ==============================================================================
# Automated DNS CNAME record creation to prove domain ownership to AWS Certificate Manager
resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

# ==============================================================================
# ACM Certificate Validation Barrier
# ==============================================================================
# Waits for DNS validation to complete before dependent resources start provisioning
resource "aws_acm_certificate_validation" "api_cert_verify" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}