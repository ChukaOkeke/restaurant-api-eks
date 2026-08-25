# ==============================================================================
# COMPUTE MODULE OUTPUT VALUES
# ==============================================================================

output "cluster_name" {
  description = "Name of the EKS Cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for Kubernetes API Server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "ecr_repository_url" {
  description = "URL of the application ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "pod_identity_agent_eksaddon_default_version" {
  value = data.aws_eks_addon_version.pia_default.version
}

output "pod_identity_agent_eksaddon_latest_version" {
  value = data.aws_eks_addon_version.pia_latest.version
}
output "pod_identity_agent_eksaddon_arn" {
  value = aws_eks_addon.pod_identity.arn
}

output "pod_identity_agent_eksaddon_id" {
  value = aws_eks_addon.pod_identity.id
}

output "lbc_iam_policy_arn" {
  value = aws_iam_policy.aws_lbc.arn
}

output "lbc_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = aws_iam_role.aws_lbc.arn
}