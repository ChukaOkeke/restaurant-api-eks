# ==============================================================================
# ENDPOINTS-SG MODULE DATA SOURCES
# Retrieves global managed prefix lists and region information
# ==============================================================================

# Fetches the current AWS region dynamically to construct interface endpoint service names
data "aws_region" "current" {}

# Fetches the AWS-managed prefix list containing all global CloudFront edge IP ranges.
# This guarantees that the Application Load Balancer ONLY accepts ingress traffic from CloudFront.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}