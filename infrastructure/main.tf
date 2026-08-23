# ==============================================================================
# ROOT MODULE ORCHESTRATION
# Invokes sub-modules in sequence passing global state variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Module 1: VPC & Base Networking
# ------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  environment               = var.environment
  cluster_name              = var.cluster_name
  vpc_cidr                  = var.vpc_cidr
  public_subnets            = var.public_subnets
  private_subnets           = var.private_subnets
  enable_single_nat_gateway = var.enable_single_nat_gateway
}

# ------------------------------------------------------------------------------
# Module 2: VPC Endpoints & Security Groups
# ------------------------------------------------------------------------------
module "endpoints_sg" {
  source = "./modules/endpoints-sg"

  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  db_port                 = var.db_port
}