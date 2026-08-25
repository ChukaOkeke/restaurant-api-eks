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

# ------------------------------------------------------------------------------
# Module 3: Security (App Secrets & OIDC Identity Federation)
# ------------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  environment = var.environment
  github_org  = var.github_org
  github_repo = var.github_repo
}

# ------------------------------------------------------------------------------
# Module 4: Compute (EKS Cluster, System Nodes, Pod Identity, ECR, & ArgoCD)
# ------------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  environment                         = var.environment
  cluster_name                        = var.cluster_name
  cluster_version                     = var.cluster_version
  cluster_endpoint_private_access     = var.cluster_endpoint_private_access
  cluster_endpoint_public_access      = var.cluster_endpoint_public_access
  node_instance_types                 = var.node_instance_types
  node_capacity_type                  = var.node_capacity_type
  vpc_id                              = module.vpc.vpc_id
  private_subnet_ids                  = module.vpc.private_subnet_ids
  eks_control_plane_security_group_id = module.endpoints_sg.eks_control_plane_security_group_id
  eks_node_security_group_id          = module.endpoints_sg.eks_node_security_group_id
  app_secret_arn                      = module.security.app_secret_arn
}

# ------------------------------------------------------------------------------
# Module 5: Database (Subnet Group & RDS PostgreSQL instance)
# ------------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.endpoints_sg.database_security_group_id
  db_instance_class  = var.db_instance_class
  multi_az           = var.multi_az
}