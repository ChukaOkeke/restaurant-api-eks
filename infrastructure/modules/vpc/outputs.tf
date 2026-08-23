# ==============================================================================
# VPC MODULE OUTPUT VALUES
# Exports resource parameters required by downstream modules (Endpoints, Compute, DB)
# ==============================================================================

output "vpc_id" {
  description = "The ID of the provisioned VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

output "private_subnet_ids_map" {
  description = "Map of AZ name to private subnet ID"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "private_route_table_ids" {
  description = "List of private route table IDs (Needed for VPC S3 Gateway Endpoint association)"
  value       = [for rt in aws_route_table.private : rt.id]
}

output "nat_gateway_ips" {
  description = "Public Elastic IP addresses assigned to the NAT Gateway(s)"
  value       = [for eip in aws_eip.nat : eip.public_ip]
}