# ==============================================================================
# ENDPOINTS-SG MODULE MAIN RESOURCES
# Provisions Security Group Containers, Standalone Decoupled Rules, and Private VPC Endpoints
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SECURITY GROUP CONTAINERS (Created without inline rules to prevent cycles)
# ------------------------------------------------------------------------------

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "restaurant-api-${var.environment}-alb-sg"
  description = "Ingress security group for Public Edge Application Load Balancer"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV2_AWS_5:Security group uses decoupled standalone rules to avoid cyclical dependencies.

  tags = {
    Name = "restaurant-api-${var.environment}-alb-sg"
  }
}

# EKS Control Plane Security Group
resource "aws_security_group" "eks_control_plane" {
  name        = "restaurant-api-${var.environment}-eks-control-plane-sg"
  description = "Security group for EKS Kubernetes API Server Control Plane"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV2_AWS_5:Security group uses decoupled standalone rules to avoid cyclical dependencies.

  tags = {
    Name = "restaurant-api-${var.environment}-eks-control-plane-sg"
  }
}

# EKS Worker Nodes Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "restaurant-api-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS Worker Nodes and workload pods"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV2_AWS_5:Security group uses decoupled standalone rules to avoid cyclical dependencies.

  tags = {
    Name                                       = "restaurant-api-${var.environment}-eks-nodes-sg"
    "kubernetes.io/cluster/restaurant-api-eks" = "owned"
    "karpenter.sh/discovery"                   = "restaurant-api-eks"
  }
}

# VPC Interface Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "restaurant-api-${var.environment}-vpc-endpoints-sg"
  description = "Security group for shared AWS VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV2_AWS_5:Security group uses decoupled standalone rules to avoid cyclical dependencies.

  tags = {
    Name = "restaurant-api-${var.environment}-vpc-endpoints-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "restaurant-api-${var.environment}-database-sg"
  description = "Security group for RDS PostgreSQL Multi-AZ cluster"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV2_AWS_5:Security group uses decoupled standalone rules to avoid cyclical dependencies.

  tags = {
    Name = "restaurant-api-${var.environment}-database-sg"
  }
}


# ------------------------------------------------------------------------------
# 2. DECOUPLED STANDALONE SECURITY GROUP RULES
# ------------------------------------------------------------------------------

# --- ALB RULES ---
resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS inbound strictly from CloudFront Managed Prefix List"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow traffic from ALB to EKS worker node workloads"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# --- CONTROL PLANE RULES ---
resource "aws_vpc_security_group_ingress_rule" "control_plane_from_nodes" {
  security_group_id            = aws_security_group.eks_control_plane.id
  description                  = "Allow HTTPS API communication from worker nodes to API Server"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "control_plane_to_nodes_kubelet" {
  security_group_id            = aws_security_group.eks_control_plane.id
  description                  = "Allow control plane to reach worker node kubelet (port 10250)"
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "control_plane_to_nodes_https" {
  security_group_id            = aws_security_group.eks_control_plane.id
  description                  = "Allow control plane to reach worker node extension webhooks (port 443)"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# --- WORKER NODE RULES ---
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow ingress from ALB to pods/NodePorts"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_control_plane" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow control plane communication to worker node kubelet & webhooks"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_control_plane.id
}

resource "aws_vpc_security_group_ingress_rule" "nodes_intra_communication" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow full pod-to-pod and node-to-node inter-communication"
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_endpoints" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow worker nodes/pods to reach AWS VPC Interface Endpoints over HTTPS"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_database" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow worker nodes/pods to reach RDS PostgreSQL database"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database.id
}

resource "aws_vpc_security_group_egress_rule" "nodes_outbound_internet" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow worker nodes outbound access for external image pulls and public APIs"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  # checkov:skip=CKV_AWS_382:Full egress is intentionally allowed from the worker nodes for external image pulls and public APIs. Access to the worker nodes is tightly controlled via ingress rules and IAM policies, ensuring that only authorized personnel can utilize this access point.
}

# --- VPC ENDPOINTS RULES ---
resource "aws_vpc_security_group_ingress_rule" "endpoints_from_nodes" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Allow HTTPS from EKS worker nodes to VPC Interface Endpoints"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# --- DATABASE RULES ---
resource "aws_vpc_security_group_ingress_rule" "database_from_nodes" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow PostgreSQL access strictly from EKS worker node workloads"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}


# ------------------------------------------------------------------------------
# 3. VPC INTERFACE ENDPOINTS (Private API Access for EKS Workloads)
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
# 4. AMAZON S3 GATEWAY ENDPOINT (Cost-Optimized Private Routing for Image Layers & S3)
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