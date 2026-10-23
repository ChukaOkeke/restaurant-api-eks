# ==============================================================================
# SECURITY MODULE INPUT VARIABLES
# Declarative variables required to construct app secrets and identity roles
# ==============================================================================

variable "environment" {
  description = "Target deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user account owning the application repo"
  type        = string
}

variable "github_repo" {
  description = "Name of the target GitHub application repository"
  type        = string
}

variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
}

variable "redis_primary_endpoint_address" {
  description = "Redis primary endpoint address"
  type        = string
}