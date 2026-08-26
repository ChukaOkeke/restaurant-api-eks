# ==============================================================================
# Route 53 Apex Domain Alias Pointer
# ==============================================================================
# Maps asgardcuisines.link directly to the CloudFront Distribution edge target
resource "aws_route53_record" "api_dns_pointer" {
  name            = var.domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.primary.zone_id
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.api_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.api_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}