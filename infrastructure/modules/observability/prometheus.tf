# ------------------------------------------------------------------------------
# Amazon Managed Service for Prometheus (AMP) Configuration
# Provides a scalable time-series database for ADOT metrics ingestion.
# ------------------------------------------------------------------------------

# Provision AMP Workspace
resource "aws_prometheus_workspace" "this" {
  alias = "${var.cluster_name}-${var.environment}-amp"

  tags = {
    Name = "${var.cluster_name}-${var.environment}-amp-workspace"
  }
}