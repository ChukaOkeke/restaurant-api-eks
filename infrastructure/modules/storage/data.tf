# ==============================================================================
# Data Source: AWS Account ID
# ==============================================================================
# Used to append the AWS Account ID to the S3 bucket name, guaranteeing global uniqueness.
data "aws_caller_identity" "current" {}