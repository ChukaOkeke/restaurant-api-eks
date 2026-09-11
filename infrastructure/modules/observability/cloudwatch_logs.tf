# ------------------------------------------------------------------------------
# Amazon CloudWatch Logs Configuration
# Centralized log storage for ADOT DaemonSet container log shipping.
# ------------------------------------------------------------------------------

# Provision CloudWatch Log Group for Application & Cluster Container Logs
resource "aws_cloudwatch_log_group" "container_logs" {
  name              = "/aws/eks/${var.cluster_name}/${var.environment}/containers"
  retention_in_days = var.log_retention_in_days

  #checkov:skip=CKV_AWS_158: AWS managed server-side encryption (SSE-AES256) is enabled by default; KMS CMK omitted to prevent unnecessary key costs.
  #checkov:skip=CKV_AWS_338: 14-day log retention configured intentionally for capstone cost control; 1-year retention is not required for ephemeral cluster load testing.

  tags = {
    Name = "${var.cluster_name}-${var.environment}-cw-logs"
  }
}