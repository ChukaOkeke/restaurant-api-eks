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

