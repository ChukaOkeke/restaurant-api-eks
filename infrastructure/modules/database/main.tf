# ==============================================================================
# DATABASE MODULE MAIN RESOURCES
# ==============================================================================

# DB Subnet Group spanning private subnets across multiple AZs (Tells RDS which subnets it is allowed to use)
resource "aws_db_subnet_group" "this" {
  name        = "restaurant-api-${var.environment}-rds-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Private DB subnet group for PostgreSQL RDS cluster"

  tags = {
    Name = "restaurant-api-${var.environment}-rds-subnet-group"
  }
}

# RDS PostgreSQL Instance (The Compute Nodes)
resource "aws_db_instance" "this" {
  identifier            = "restaurant-api-${var.environment}-db"
  engine                = "postgres"
  engine_version        = "16" # Pin to major version 16 to auto-resolve active minor releases
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "asgard_cuisines_db"
  username = "dbadmin"

  # Best Practice: AWS automatically manages, rotates, and stores the password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = true # Set to false in actual production to avoid data loss on destroy

  tags = {
    Name = "restaurant-api-${var.environment}-db"
  }
}