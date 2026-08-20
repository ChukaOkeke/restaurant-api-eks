# ==========================================
# DEFINE THE GLOBAL PROJECT VARIABLES
# This file passes the configuration values from your execution environment down into the root orchestrator.
# ==========================================

variable "aws_primary_region" {
  description = "The primary AWS region to deploy resources in"
  type        = string
  default     = "eu-west-1"
}

variable "aws_secondary_region" {
  description = "The AWS region to deploy WAF and ACM for CloudFront in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}


# VPC CONFIGURATIONS
variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the custom VPC"
  default     = "10.16.0.0/16"
}

variable "public_subnets" {
  type        = map(string)
  description = "Public subnets per availability zone"
  default = {
    "eu-west-1a" = "10.16.1.0/24"
    "eu-west-1b" = "10.16.2.0/24"
    "eu-west-1c" = "10.16.3.0/24"
  }
}

variable "private_subnets" {
  type        = map(string)
  description = "Private subnets per availability zone"
  default = {
    "eu-west-1a" = "10.16.10.0/24"
    "eu-west-1b" = "10.16.11.0/24"
    "eu-west-1c" = "10.16.12.0/24"
  }
}

variable "db_port" {
  type        = number
  description = "The network port for the database cluster"
  default     = 5432 # Defaulting to PostgreSQL for clean setup
}


# MESSAGING CONFIGURATIONS (Asynchronous Queue Tuning)


# SECURITY CONFIGURATIONS (OIDC CI/CD Settings)

variable "github_org" {
  type        = string
  description = "Your GitHub username or organization name"
  default     = "ChukaOkeke" # Replace with your real target github name
}

variable "github_repo" {
  type        = string
  description = "The exact application repository name matching your workplace path"
  default     = "restaurant-api-eks" # Replace with your real target repo name
}


# ROUTE53 DNS CONFIGURATIONS
variable "domain_name" {
  type        = string
  default     = "asgardcuisines.link" # Replace with your real registered domain name
  description = "Your registered custom base apex domain zone"
}


# COMPUTE CONFIGURATIONS 
