# ------------------------------------------------------------------------------
# Amazon CloudWatch Logs Configuration
# Centralized log storage for ADOT DaemonSet container log shipping.
# ------------------------------------------------------------------------------

# Provision CloudWatch Log Group for Application & Cluster Container Logs
resource "aws_cloudwatch_log_group" "container_logs" {
  name              = "/aws/eks/${var.cluster_name}/${var.environment}/containers"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.cluster_name}-${var.environment}-cw-logs"
  }
}