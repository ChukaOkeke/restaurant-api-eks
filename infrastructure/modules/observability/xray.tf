# ------------------------------------------------------------------------------
# AWS X-Ray Tracing Configuration
# Configures distributed tracing sampling rules and OTLP trace export permissions.
# ------------------------------------------------------------------------------

# Define Custom X-Ray Sampling Rule for High-Priority API Traces
resource "aws_xray_sampling_rule" "app_tracing" {
  rule_name      = "${var.cluster_name}-${var.environment}-api-sampling"
  priority       = 1000
  reservoir_size = 1
  fixed_rate     = 0.05
  host           = "*"
  http_method    = "*"
  url_path       = "*"
  version        = 1
  service_name   = "restaurant-api"
  service_type   = "*"
  resource_arn   = "*"

  tags = {
    Name = "${var.cluster_name}-${var.environment}-api-xray-sampling"
  }
}