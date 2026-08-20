# ==========================================
# ROOT PROVIDER CONFIGURATIONS & DEFAULT TAGS (RECOMMENDED FOR FINOPS)
# This file initializes the downloaded AWS provider binary and applies the operational rules, like the region and AWS account selection, and the global FinOps tagging strategy.
# ==========================================

# Primary Regional Provider
provider "aws" {
  region = var.aws_primary_region
  # Access keys can be set in the environment variables or through the AWS CLI configuration

  # Cascades the granular tagging strategy down to every single sub-resource
  default_tags {
    tags = {
      Project     = "Restaurant-API"
      CostCenter  = "Engineering"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Global Edge Provider (For CloudFront WAF & ACM Certificate compliance).
provider "aws" {
  alias  = "us_east_1"
  region = var.aws_cloudfront_compliance_region

  default_tags {
    tags = {
      Project     = "Restaurant-API"
      CostCenter  = "Engineering"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}