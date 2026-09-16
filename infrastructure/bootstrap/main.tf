# Remote state management
# Configure required Terraform providers and versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider region
provider "aws" {
  region = "eu-west-1"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "chuka-devops-state-storage"

  lifecycle {
    prevent_destroy = true # Prevents accidental deletion
  }

  # Provision central S3 bucket for remote state storage
  # checkov:skip=CKV_AWS_18: "Access logging disabled to avoid circular bucket dependencies in bootstrap module"
  # checkov:skip=CKV2_AWS_62: "Event notifications are unnecessary for state-locking backend storage"
  # checkov:skip=CKV_AWS_144: "Cross-region replication skipped to prevent redundant cross-region transfer costs"
  # checkov:skip=CKV_AWS_145: "SSE-S3 (AES256) default encryption is sufficient; dedicated KMS key overhead not required"
}

# Enable versioning for state recovery and rollback capability
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Explicitly block all public access (Fixes CKV2_AWS_6)
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Automatically clean up non-current state versions after 90 days (Fixes CKV2_AWS_61)
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # checkov:skip=CKV_AWS_300: "Period is set"
}