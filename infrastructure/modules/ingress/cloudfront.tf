# ==============================================================================
# CloudFront Origin Access Control (OAC)
# ==============================================================================
# Restricts S3 bucket reads exclusively to authenticated CloudFront requests
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "restaurant-api-${var.environment}-s3-oac"
  description                       = "Origin Access Control for static media S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ======================================================================================
# CloudFront Distribution (Dual-Origin Architecture -- ALB + S3) and Path-Based Routing
# ======================================================================================
resource "aws_cloudfront_distribution" "api_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"
  web_acl_id      = aws_wafv2_web_acl.cloudfront_waf.arn # Associate WAF with CloudFront distribution

  aliases = [var.domain_name] # Using the apex domain for the CloudFront distribution (e.g., asgardcuisines.link)

  # Dynamic Backend Origin (ALB / Ingress Controller)
  origin {
    domain_name = var.backend_domain_name # Target endpoint for backend compute / ingress controller (e.g., ALB DNS name)
    origin_id   = "BackendComputeOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # Enforces Segment 2 security bounds (CloudFront to ALB communication must be encrypted)
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Static Assets Origin (S3 Bucket via OAC)
  origin {
    domain_name              = var.static_bucket_regional_domain_name # S3 bucket regional domain name (e.g., mybucket.s3.eu-west-1.amazonaws.com)
    origin_id                = "S3StaticBucketOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Behavior 1: Route /static/* requests straight to S3
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3StaticBucketOrigin"
    viewer_protocol_policy = "redirect-to-https" # Enforces Segment 1 client security edge (redirects all HTTP traffic to HTTPS)

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0        # Minimum cache time for static assets (0 seconds)
    default_ttl = 86400    # Default cache for 1 day
    max_ttl     = 31536000 # Max cache 1 year
  }

  # Default Behavior: Direct dynamic application & API traffic to backend compute
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "BackendComputeOrigin"
    viewer_protocol_policy = "redirect-to-https" # Enforces Segment 1 client security edge (redirects all HTTP traffic to HTTPS)

    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id # Inject secure edge headers via AWS Managed Policy

    forwarded_values {
      query_string = true

      # Explicitly list required headers to ensure the 'Host' header is NOT forwarded.
      # If 'Host' is forwarded, ALB will reject the request with a 403 Forbidden.
      headers = [
        "Accept",
        "Accept-Language",
        "Authorization",
        "Content-Type",
        "Origin",
        "Referer"
      ]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {

      # checkov:skip=CKV_AWS_374:Geo restriction is disabled to ensure the application endpoints remain universally accessible to global users and remote infrastructure.
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.api_cert_verify.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # checkov:skip=CKV_AWS_310:Multi-region origin failover is disabled in dev to avoid multi-region infrastructure costs; native single-region Multi-AZ tier availability is sufficient.
  # checkov:skip=CKV_AWS_86:CloudFront edge access logging is bypassed to eliminate S3 log storage costs; incoming traffic tracking is already handled via ALB CloudWatch logs.
  # checkov:skip=CKV_AWS_305:Default root object is bypassed because this distribution acts as an API proxy; forcing a static index.html disrupts application-level REST API root route resolution.
  # checkov:skip=CKV2_AWS_47:Log4j mitigation rules are bypassed because the underlying backend compute tier is exclusively built on Python (Django), rendering the stack structurally immune to Java Log4j exploits. Adding this group introduces unnecessary WCU consumption and rule overhead for zero active utility.

  tags = {
    Name = "restaurant-api-${var.environment}-api-cdn"
  }
}

# ==============================================================================
# S3 Bucket Policy for CloudFront OAC Access
# ==============================================================================
# Placed here to prevent circular dependency cycles between Storage and Ingress
resource "aws_s3_bucket_policy" "static_assets_oac_policy" {
  # We use the id passed from the storage module via the root
  bucket = var.static_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.static_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.api_cdn.arn
          }
        }
      }
    ]
  })
}