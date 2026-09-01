# ==============================================================================
# COMPUTE MODULE INPUT VARIABLES
# ==============================================================================

variable "environment" {
  description = "Target deployment environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes control plane version"
  type        = string
}

variable "cluster_endpoint_private_access" {
  description = "Whether to enable private access to EKS control plane endpoint"
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Whether to enable public access to EKS control plane endpoint"
  type        = bool
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs for node group and pod workloads"
  type        = list(string)
}

variable "eks_control_plane_security_group_id" {
  description = "Security group ID for the EKS Control Plane"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "Security group ID for EKS Worker Nodes"
  type        = string
}

variable "app_secret_arn" {
  description = "ARN of the Secrets Manager App secret for External Secrets Operator access"
  type        = string
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Instance capacity type: ON_DEMAND or SPOT"
  type        = string
}

variable "domain_name" {
  type        = string
  description = "Apex domain name registered in Route 53 (e.g., asgardcuisines.link)"
}