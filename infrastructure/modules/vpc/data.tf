# ==============================================================================
# VPC MODULE DATA SOURCES
# Fetches active Availability Zones in the primary deployment region
# ==============================================================================

# Fetches all available AZs in the current region to validate subnet mappings
data "aws_availability_zones" "available" {
  state = "available"
}