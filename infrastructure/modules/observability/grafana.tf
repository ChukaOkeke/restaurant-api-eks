# ------------------------------------------------------------------------------
# Amazon Managed Grafana (AMG) Workspace & Identity Configuration
# Single Pane of Glass for querying AMP, CloudWatch Logs, and X-Ray.
# ------------------------------------------------------------------------------

# 1. IAM Role Assumed by Amazon Managed Grafana Workspace
resource "aws_iam_role" "grafana" {
  name = "${var.cluster_name}-${var.environment}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-${var.environment}-grafana-role"
  }
}

# 2. Attach Data Source Read Policies to AMG Role
resource "aws_iam_role_policy" "grafana_datasources" {
  name = "${var.cluster_name}-${var.environment}-grafana-datasource-policy"
  role = aws_iam_role.grafana.id

  #checkov:skip=CKV_AWS_355: AWS X-Ray and CloudWatch DescribeLogGroups APIs do not support resource-level permissions and require wildcard '*' by AWS design.

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Amazon Managed Prometheus Querying (Scoped to Workspace)
      {
        Sid    = "AMPServerQuery"
        Effect = "Allow"
        Action = [
          "aps:QueryMetrics",
          "aps:GetMetricMetadata",
          "aps:GetSeries",
          "aps:GetLabels"
        ]
        Resource = aws_prometheus_workspace.this.arn
      },
      # 2. CloudWatch Log Content Querying (Scoped strictly to Log Group ARN)
      {
        Sid    = "CloudWatchLogsScopedRead"
        Effect = "Allow"
        Action = [
          "logs:GetLogDelivery",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults"
        ]
        Resource = [
          aws_cloudwatch_log_group.container_logs.arn,
          "${aws_cloudwatch_log_group.container_logs.arn}:*"
        ]
      },
      # 3. CloudWatch Log Discovery (Requires '*' as Describe APIs do not support ARNs)
      {
        Sid      = "CloudWatchLogsDiscovery"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      },
      # 4. AWS X-Ray Read (Requires '*' as X-Ray read APIs do not support ARNs)
      {
        Sid    = "XRayRead"
        Effect = "Allow"
        Action = [
          "xray:BatchGetTraces",
          "xray:GetTraceSummaries",
          "xray:GetTraceGraph",
          "xray:GetGroups",
          "xray:GetServiceGraph"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Provision AMG Workspace
# Configured for IAM Identity Center authentication and service-managed permissions.
resource "aws_grafana_workspace" "this" {
  name                     = "${var.cluster_name}-${var.environment}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"] # AWS Identity Center
  permission_type          = "CUSTOMER_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn

  # Data sources that Grafana can query
  data_sources = ["PROMETHEUS", "CLOUDWATCH", "XRAY"]

  tags = {
    Name = "${var.cluster_name}-${var.environment}-amg-workspace"
  }
}