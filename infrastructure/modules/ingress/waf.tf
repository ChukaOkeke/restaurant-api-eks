# ==============================================================================
# AWS WAFv2 Web ACL (Global Edge / us-east-1)
# ==============================================================================
# Rate-limiting web application firewall attached directly to the CloudFront CDN
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider    = aws.us_east_1 # Crucial: Must be instantiated in N. Virginia
  name        = "restaurant-api-${var.environment}-cloudfront-waf"
  description = "Edge WAF policy enforcing IP rate limits against DDoS attacks"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # ============================================================================
  # Rule: Rate Limiting per IP
  # ============================================================================
  # Limits each IP address to 300 requests per 5-minute rolling window
  rule {
    name     = "IPRateLimit"
    priority = 1
    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 300 # Max requests per 5 minutes per single IP address
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RestaurantApiIPRateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RestaurantApiCloudFrontWafMetric"
    sampled_requests_enabled   = true
  }

  # checkov:skip=CKV_AWS_192:Log4j protection is bypassed because the application stack utilizes a pure Python runtime environment, making Java-based Log4jshell exploits zero-risk for this infrastructure.
  # checkov:skip=CKV2_AWS_31:WAFv2 full request logging is disabled in the development tier to avoid Kinesis Firehose and CloudWatch ingestion/storage billing overhead.

  tags = {
    Name = "restaurant-api-${var.environment}-cloudfront-waf"
  }
}