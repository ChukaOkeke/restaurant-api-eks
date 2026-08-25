# ==============================================================================
# GITOPS BOOTSTRAP: ARGOCD INSTALLATION
# Deploys ArgoCD Helm chart directly to EKS upon cluster creation
# ==============================================================================

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "10.4.0"
  replace          = true # Overwrites orphaned release state from the previous failed apply

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]

  depends_on = [
    aws_eks_node_group.system,
    aws_eks_addon.pod_identity
  ]
}