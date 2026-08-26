# Version constraints for the Ingress module

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws, aws.us_east_1] # Requires the root to hand over the aliases for both the primary and compliance regions
    }
  }
}