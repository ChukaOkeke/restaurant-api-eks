# ==============================================================================
# EKS CONTROL PLANE, SYSTEM NODE GROUP, & NATIVE ADD-ONS
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. EKS Control Plane IAM Role & Policy Attachments
# This role is assumed by the EKS service to manage the control plane resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "restaurant-api-${var.environment}-eks-cluster-role"

  # Trust policy to allow EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = {
    Name = "restaurant-api-${var.environment}-eks-cluster-role"
  }
}

# ------------------------------------------------------------------------------
# Attach the required policy for EKS to manage cluster control plane
# This is mandatory for all EKS clusters
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ------------------------------------------------------------------------------
# Attach VPC Resource Controller policy
# Required for advanced networking, Fargate, and Karpenter support
# Recommended to include by default for production-grade EKS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}


# ------------------------------------------------------------------------------
# 2. Create the AWS EKS Cluster
# This is the control plane for Kubernetes on AWS
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  # The name of the EKS cluster
  name = var.cluster_name

  # Kubernetes version to use for the control plane
  version = var.cluster_version

  #checkov:skip=CKV_AWS_339: Cluster version is dynamically injected via variable and verified against supported AWS EKS releases.

  # IAM role used by EKS to manage the control plane
  role_arn = aws_iam_role.cluster.arn

  #checkov:skip=CKV_AWS_58: External Secrets Operator (ESO) with AWS Secrets Manager manages secret lifecycles directly, mitigating etcd persistence risks in this environment. Avoid the customer-managed KMS key charge in a dev environment
  #checkov:skip=CKV_AWS_39: Public API endpoint enabled to allow external GitHub Actions CI/CD deployment without complex VPN/Bastion infrastructure overhead.
  #checkov:skip=CKV_AWS_38: Public access CIDR unrestricted to allow dynamic GitHub Actions hosted runners to execute kubectl/Helm deployments.

  # VPC configuration for control plane networking
  vpc_config {
    # Subnets where EKS control plane ENIs will be placed (should be private)
    subnet_ids = var.private_subnet_ids

    # Security groups for the EKS control plane (must allow inbound from and outbound to worker nodes)
    security_group_ids = [var.eks_control_plane_security_group_id]

    # Allow access to private endpoint (inside VPC)
    endpoint_private_access = var.cluster_endpoint_private_access

    # Allow access to public endpoint (from internet, controlled via CIDRs)
    endpoint_public_access = var.cluster_endpoint_public_access # Set false in locked down enterprise setup
  }

  # Enable EKS control plane logging for visibility and debugging
  enabled_cluster_log_types = [
    "api",               # API server audit logs
    "audit",             # Kubernetes audit logs
    "authenticator",     # Authenticator logs for IAM auth
    "controllerManager", # Logs for controller manager
    "scheduler"          # Logs for pod scheduling
  ]

  # Ensure IAM policy attachments complete before cluster creation
  # Helps avoid race conditions during provisioning and destroy
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController
  ]

  tags = {
    Name = var.cluster_name
  }
}


# ------------------------------------------------------------------------------
# 3. IAM Role for EKS Managed Node Group (EC2 Worker Nodes)
# This role will be assumed by EC2 instances launched in the node group
# ------------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  name = "restaurant-api-${var.environment}-eks-node-group-role"

  # Trust policy: allow EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "restaurant-api-${var.environment}-eks-node-group-role"
  }
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEKSWorkerNodePolicy
# Grants basic node group access to the EKS cluster
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEKS_CNI_Policy
# Allows nodes to manage networking (ENIs) via the VPC CNI plugin
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEC2ContainerRegistryReadOnly
# Grants nodes permission to pull images from Amazon ECR
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonSSMManagedInstanceCore
# Grants core SSM managed instance capabilities
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}


# ---------------------------------------------------------------------------------------------
# 4. System Managed Node Group (Runs CoreDNS, ArgoCD, Controllers before Karpenter takes over)
# ---------------------------------------------------------------------------------------------
# Launch template for the system node group to attach a custom security group
resource "aws_launch_template" "system_nodes" {
  name_prefix   = "${var.cluster_name}-system-node-lt-"
  description   = "Launch template for EKS system node group custom security group attachment"
  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforces IMDSv2
    http_put_response_hop_limit = 2          # Required for EKS containerized workloads
  }

  # Security groups for the worker nodes
  vpc_security_group_ids = [
    var.eks_node_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-system-node"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  # Lifecycle rule to ensure the launch template is created before destroying the old one
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "system" {
  # The name of the EKS cluster this node group belongs to
  cluster_name = aws_eks_cluster.this.name

  # Logical name for this node group in the EKS cluster
  node_group_name = "system-components-ng"

  # IAM role that EC2 worker nodes will assume
  node_role_arn = aws_iam_role.node_group.arn

  # Subnets where the worker nodes will be launched (typically private subnets)
  subnet_ids = var.private_subnet_ids

  # Instance types for the nodes (e.g., t3.medium, m5.large)
  instance_types = var.node_instance_types

  # Choose between ON_DEMAND or SPOT capacity types
  capacity_type = var.node_capacity_type

  # Use Amazon Linux 2023 AMI — the latest Amazon-managed OS optimized for EKS
  # Fully supported in Kubernetes v1.25+ and production-ready
  # Better security, updated packages, and long-term support (recommended over AL2)
  ami_type = "AL2023_x86_64_STANDARD"

  # Reference the Launch Template for custom security group attachment
  launch_template {
    name    = aws_launch_template.system_nodes.name
    version = aws_launch_template.system_nodes.latest_version
  }

  # Configure auto-scaling limits and defaults
  scaling_config {
    # Desired number of nodes when the node group is created
    desired_size = 3

    # Minimum number of nodes allowed
    min_size = 1

    # Maximum number of nodes the group can scale to
    max_size = 6
  }

  # Set the max percentage of nodes that can be unavailable during update
  update_config {
    max_unavailable_percentage = 33
  }

  # Force node group update when EKS AMI version changes
  force_update_version = true

  # Kubernetes labels applied to the nodes upon joining the cluster
  labels = {
    # Matches the Helm values nodeSelector rule
    "karpenter.sh/discovery" = var.cluster_name
    "intent"                 = "system"
  }

  tags = {
    Name = "restaurant-api-${var.environment}-system-node-group"
  }

  # Ensure IAM role policies are attached before creating the node group
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]
}


# ------------------------------------------------------------------------------
# 5. Core EKS Addons (Including EKS Pod Identity Agent)
# ------------------------------------------------------------------------------
# # EKS Addon: Pod Identity Agent
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"

  # Prevent Helm or default EKS bootstrap collisions on addon creation and update.
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "restaurant-api-${var.environment}-addon-pod-identity"
  }

  # Use the latest EKS addon version compatible with the cluster's Kubernetes version
  addon_version = data.aws_eks_addon_version.pia_latest.version

  depends_on = [aws_eks_node_group.system]
}

# EKS Addon: VPC CNI (Amazon VPC CNI Plugin for Kubernetes)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  tags = {
    Name = "restaurant-api-${var.environment}-addon-vpc-cni"
  }

  depends_on = [aws_eks_node_group.system]
}

# EKS Addon: CoreDNS (Kubernetes DNS Server)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  tags = {
    Name = "restaurant-api-${var.environment}-addon-coredns"
  }

  depends_on = [aws_eks_node_group.system]
}

# EKS Addon: Kube Proxy (Kubernetes Network Proxy)
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  tags = {
    Name = "restaurant-api-${var.environment}-addon-kube-proxy"
  }

  depends_on = [aws_eks_node_group.system]
}