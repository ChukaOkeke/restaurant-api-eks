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

# --- Module 2: Security Groups Outputs ---
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.endpoints_sg.alb_security_group_id
}

output "eks_control_plane_security_group_id" {
  description = "EKS Control Plane Security Group ID"
  value       = module.endpoints_sg.eks_control_plane_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS Worker Nodes Security Group ID"
  value       = module.endpoints_sg.eks_node_security_group_id
}

output "database_security_group_id" {
  description = "RDS Database Security Group ID"
  value       = module.endpoints_sg.database_security_group_id
}

# --- Security Outputs ---
output "app_secret_arn" {
  description = "Application Secrets Manager Container ARN"
  value       = module.security.app_secret_arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Execution IAM Role ARN"
  value       = module.security.github_actions_role_arn
}

# --- Compute Outputs ---
output "cluster_name" {
  description = "Name of the EKS Cluster"
  value       = module.compute.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API Server Endpoint"
  value       = module.compute.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = module.compute.ecr_repository_url
}