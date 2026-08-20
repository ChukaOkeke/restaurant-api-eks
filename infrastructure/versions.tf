# ==========================================
# ROOT VERSION CONSTRAINTS & REQUIREMENTS
# This file defines the Terraform version and provider requirements for the entire project. It dictates exactly which binaries Terraform needs to download
# ==========================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}