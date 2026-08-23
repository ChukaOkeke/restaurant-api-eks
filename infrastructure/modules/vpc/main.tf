# ==============================================================================
# VPC MODULE MAIN RESOURCES
# Provisions VPC, Subnets, Gateways, and Route Tables with EKS/Karpenter tags
# ==============================================================================

# ------------------------------------------------------------------------------
# Custom Virtual Private Cloud (VPC)
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for EKS worker nodes & PrivateLink endpoints
  enable_dns_support   = true # Required for private DNS resolution within the VPC

  # checkov:skip=CKV2_AWS_11:VPC Flow Logs are disabled in this sandbox environment to minimize high-volume CloudWatch log ingestion costs during rapid prototyping cycles.

  # The default_tags from the root provider merge with this local block to ensure all resources get consistent tagging, while allowing for module-specific tags as needed

  tags = {
    Name = "restaurant-api-${var.environment}-vpc"
  }
}

# ------------------------------------------------------------------------------
# Internet Gateway (Public Internet Entry for Public Subnets)
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "restaurant-api-${var.environment}-igw"
  }
}

# ------------------------------------------------------------------------------
# Public Subnets (For CloudFront Ingress, ALBs, & NAT Gateways)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true # Auto-assign public IPs to resources placed here

  # checkov:skip=CKV_AWS_130:Public subnets must map public IPs on launch to allow public-facing infrastructure (like NAT Gateways or ALBs) to function. Compute and database nodes remain secured inside private subnets.

  tags = {
    Name = "restaurant-api-${var.environment}-public-${each.key}"
    # Critical Tag: Tells AWS Load Balancer Controller it can provision internet-facing ALBs here
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ------------------------------------------------------------------------------
# Private Subnets (For EKS Worker Nodes, Pods, & RDS Database)
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "restaurant-api-${var.environment}-private-${each.key}"
    # Critical Tag: Tells AWS Load Balancer Controller it can provision internal load balancers here
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    # Critical Tag: Enables Karpenter to auto-discover private subnets for provisioning node capacity
    "karpenter.sh/discovery" = var.cluster_name
  }
}

# ------------------------------------------------------------------------------
# Elastic IP(s) for NAT Gateway(s)
# Creates 1 EIP in dev mode ("single") or 1 per AZ in production mode
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = var.enable_single_nat_gateway ? toset(["single"]) : toset(keys(var.public_subnets))
  domain   = "vpc"

  tags = {
    Name = "restaurant-api-${var.environment}-nat-eip-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# NAT Gateway(s) (Outbound Internet Access for Private Subnet Workloads)
# ------------------------------------------------------------------------------
resource "aws_nat_gateway" "this" {
  for_each      = var.enable_single_nat_gateway ? toset(["single"]) : toset(keys(var.public_subnets))
  allocation_id = aws_eip.nat[each.key].id
  # If single NAT, place in the first public subnet; otherwise place in local AZ public subnet
  subnet_id = aws_subnet.public[each.key == "single" ? keys(var.public_subnets)[0] : each.key].id

  tags = {
    Name = "restaurant-api-${var.environment}-nat-gw-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# Public Route Table & Subnet Associations
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "restaurant-api-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# Private Route Table(s) & Subnet Associations
# Creates 1 Route Table in dev mode ("single") or 1 per AZ in production mode
# ------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  for_each = var.enable_single_nat_gateway ? toset(["single"]) : toset(keys(var.private_subnets))
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = {
    Name = "restaurant-api-${var.environment}-private-rt-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each  = aws_subnet.private
  subnet_id = each.value.id
  # Associates to the single private RT in dev, or local zonal RT in prod
  route_table_id = var.enable_single_nat_gateway ? aws_route_table.private["single"].id : aws_route_table.private[each.key].id
}