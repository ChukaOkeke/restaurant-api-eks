# ==========================================
# ROOT PROVIDER CONFIGURATIONS & DEFAULT TAGS (RECOMMENDED FOR FINOPS)
# This file initializes the downloaded AWS provider binary and applies the operational rules, like the region and AWS account selection, and the global FinOps tagging strategy.
# ==========================================

# Primary Provider for the main deployment region
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

# Secondary Provider (For CloudFront WAF & ACM Certificate compliance).
provider "aws" {
  alias  = "us_east_1"
  region = var.aws_secondary_region

  default_tags {
    tags = {
      Project     = "Restaurant-API"
      CostCenter  = "Engineering"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Helm Provider Configuration for ArgoCD Bootstrap
provider "helm" {
  kubernetes = {
    host                   = module.compute.cluster_endpoint
    cluster_ca_certificate = base64decode(module.compute.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.compute.cluster_name]
      command     = "aws"
    }
  }
}