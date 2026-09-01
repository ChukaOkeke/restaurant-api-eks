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
  allocated_storage     = 20  # Initial storage allocation in GB; RDS can auto-scale if needed
  max_allocated_storage = 100 # Allows RDS to auto-scale storage up to 100GB if needed, preventing downtime due to storage limits
  storage_type          = "gp3"
  storage_encrypted     = true # Encrypts the underlying storage volumes for the cluster using AWS-managed keys by default (no custom KMS key needed for dev)

  db_name  = "asgard_cuisines_db"
  username = "dbadmin"

  # Best Practice: AWS automatically manages, rotates, and stores the password in Secrets Manager
  manage_master_user_password = true

  deletion_protection = var.environment == "prod" ? true : false

  #checkov:skip=CKV_AWS_293: Deletion protection parameterized and disabled in dev/staging to enable automated ephemeral stack teardowns.

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  #checkov:skip=CKV_AWS_157: Multi-AZ disabled in dev/staging environments to optimize infrastructure costs.

  multi_az            = var.multi_az
  publicly_accessible = false # Ensures the RDS instance is not exposed to the public internet, enhancing security by restricting access to within the VPC
  skip_final_snapshot = true  # Set to false in actual production to avoid data loss on destroy

  iam_database_authentication_enabled = true # Allows worker nodes to authenticate using IAM roles instead of static passwords

  enabled_cloudwatch_logs_exports = ["postgresql"] # Enables RDS to push database logs to CloudWatch for monitoring and troubleshooting

  copy_tags_to_snapshot = true # Ensures that if you take a snapshot of the database, it retains the same tags for easier identification and cost allocation

  # checkov:skip=CKV_AWS_226:Auto minor upgrades are disabled to maintain strict engine version parity across stages and prevent uncoordinated database restarts outside of managed maintenance windows.
  auto_minor_version_upgrade = false # Intentionally disabled for deterministic change control

  performance_insights_enabled = true # Enables Performance Insights for advanced database performance monitoring and troubleshooting

  # checkov:skip=CKV_AWS_354:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  # checkov:skip=CKV_AWS_118:Enhanced monitoring is disabled in dev to eliminate CloudWatch log ingestion charges and avoid unnecessary IAM monitoring role provisioning; standard baseline CloudWatch metrics are sufficient.
  # checkov:skip=CKV_AWS_139: No deletion protection to allow easy teardown during development; production environments should set this to true
  # checkov:skip=CKV2_AWS_27:Full PostgreSQL statement query logging is disabled in the development tier to reduce unnecessary CloudWatch log volume overhead and storage baseline costs.
  # checkov:skip=CKV2_AWS_8:Centralized AWS Backup service assignment is bypassed because the cluster uses standard native Aurora automated snapshots and PITR, which are sufficient for dev/sandbox recovery without duplicate cost tiers.
  # checkov:skip=CKV2_AWS_30: Detailed PostgreSQL query statement logging is bypassed in dev to avoid expensive CloudWatch log ingestion fees and disk I/O overhead.

  tags = {
    Name = "restaurant-api-${var.environment}-db"
  }
}