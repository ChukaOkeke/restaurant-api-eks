# ==============================================================================
# VPC MODULE INPUT VARIABLES
# Declarative variables required to construct the isolated network topology
# ==============================================================================

variable "environment" {
  description = "Target deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster (Required for K8s subnet auto-discovery tags)"
  type        = string
}

variable "vpc_cidr" {
  description = "Base IPv4 CIDR block for the custom VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of Availability Zones to public subnet CIDR blocks"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of Availability Zones to private subnet CIDR blocks"
  type        = map(string)
}

variable "enable_single_nat_gateway" {
  description = "Toggle TRUE for dev cost optimization (1 NAT GW), FALSE for production (1 NAT GW per AZ)"
  type        = bool
  default     = true
}