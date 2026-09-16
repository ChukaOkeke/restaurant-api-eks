# Remote state management
# Configure the Terraform AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Create the S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "chuka-devops-state-storage" # Must be globally unique

  lifecycle {
    prevent_destroy = true # Protects state storage from accidental deletion
  }
}

# Enable Versioning (Crucial for recovery)
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id # Reference the S3 bucket created above

  versioning_configuration {
    status = "Enabled"
  }
}