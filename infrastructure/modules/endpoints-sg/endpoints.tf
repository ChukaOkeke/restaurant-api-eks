# ------------------------------------------------------------------------------
# 1. VPC INTERFACE ENDPOINTS (Private API Access for EKS Workloads)
# ------------------------------------------------------------------------------

# Local helper to define the exact AWS service endpoints required by your backend
locals {
  interface_services = {
    ecr_api        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    ecr_dkr        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    sqs            = "com.amazonaws.${data.aws_region.current.name}.sqs"
    secretsmanager = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
    amp            = "com.amazonaws.${data.aws_region.current.name}.aps-workspaces" # Amazon Managed Prometheus
  }
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each          = local.interface_services
  vpc_id            = var.vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Interface"

  # Bind the endpoints to all private subnets for Multi-AZ high availability
  subnet_ids = var.private_subnet_ids

  # Attach the security group that explicitly trusts the worker nodes
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  # CRITICAL: Enables private DNS hostname resolution (e.g., sqs.eu-west-1.amazonaws.com resolves to private IPs in the VPC instead of public endpoints) 
  # so your Python/Django SDK code doesn't need custom endpoint URL overrides.
  private_dns_enabled = true

  tags = {
    Name = "restaurant-api-${var.environment}-${each.key}-endpoint"
  }
}


# ------------------------------------------------------------------------------
# 2. AMAZON S3 GATEWAY ENDPOINT (Cost-Optimized Private Routing for Image Layers & S3)
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically injects the private S3 routing prefix list into our private route table
  route_table_ids = var.private_route_table_ids

  tags = {
    Name = "restaurant-api-${var.environment}-s3-gateway"
  }
}