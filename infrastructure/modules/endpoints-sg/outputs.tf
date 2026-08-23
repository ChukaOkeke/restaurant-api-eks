# ==============================================================================
# ENDPOINTS-SG MODULE OUTPUT VALUES
# Exports Security Group IDs and Endpoint details for downstream modules
# ==============================================================================

output "alb_security_group_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "eks_control_plane_security_group_id" {
  description = "Security Group ID for the EKS Control Plane"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_node_security_group_id" {
  description = "Security Group ID for the EKS Worker Nodes"
  value       = aws_security_group.eks_nodes.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security Group ID for the VPC Interface Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "database_security_group_id" {
  description = "Security Group ID for the RDS PostgreSQL Database"
  value       = aws_security_group.database.id
}