# ------------------------------------------------------------------------------
# Observability Module Outputs
# Exposes provisioned endpoints and policy ARNs to the root module for ADOT Pod Identity integration.
# ------------------------------------------------------------------------------

output "amp_workspace_id" {
  value       = aws_prometheus_workspace.this.id
  description = "ID of the Amazon Managed Prometheus workspace"
}

output "amp_workspace_endpoint" {
  value       = aws_prometheus_workspace.this.prometheus_endpoint
  description = "Prometheus Remote Write endpoint for the OTel Collector"
}

output "prometheus_workspace_arn" {
  value       = aws_prometheus_workspace.this.arn
  description = "Amazon Managed Prometheus Workspace ARN"
}

output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.container_logs.name
  description = "Name of the CloudWatch Log Group designated for container logs"
}

output "cloudwatch_log_group_arn" {
  value       = aws_cloudwatch_log_group.container_logs.arn
  description = "ARN of the CloudWatch Log Group designated for container logs"
}

output "grafana_workspace_id" {
  value       = aws_grafana_workspace.this.id
  description = "ID of the Amazon Managed Grafana workspace"
}

output "grafana_workspace_endpoint" {
  value       = aws_grafana_workspace.this.endpoint
  description = "HTTPS URL endpoint to access the Grafana UI"
}