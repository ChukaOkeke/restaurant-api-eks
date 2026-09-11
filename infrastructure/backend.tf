# Configure the S3 backend for remote state management. Variables can't be used, must be hardcoded.
terraform {
  backend "s3" {
    bucket         = "chuka-devops-state-storage" # The unique bucket name
    key            = "dev/restaurant-api-eks/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
    # profile        = "iamadmin-project"
  }
}

