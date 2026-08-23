# ==============================================================================
# ROOT INFRASTRUCTURE OUTPUTS
# Exposes core networking outputs to terminal output & remote state callers
# ==============================================================================

output "vpc_id" {
  description = "The ID of the primary VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Public IP addresses of the deployed NAT Gateway(s)"
  value       = module.vpc.nat_gateway_ips
}