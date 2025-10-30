######################################################################################
#1. Install Secrets Store CSI  Driver using Helm Chart
######################################################################################

resource "helm_release" "secrets_store_csi_driver" {
  name       = "csi-secrets-store"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  cleanup_on_fail  = true
  force_update     = true
  wait_for_jobs    = true
  #atomic           = true
  timeout          = "600"

  set = [
    {
      name  = "syncSecret.enabled"
      value = "true"
    },
    {
      name  = "enableSecretRotation"
      value = "true"
    },
    {
      name  = "rotationPollInterval"
      value = "1m"
    }
  ]

  # Ensure IAM role and service account exist before Helm install
  depends_on = [
    aws_iam_role.csi_secrets_store_role,
    aws_iam_policy.csi_secrets_store_policy
  ]
  
}

# Kubernetes namespace
resource "kubernetes_namespace" "web" {
  metadata {
    name = "app"
  }
}

# Kubernetes service account
resource "kubernetes_service_account" "csi_secrets_store_driver_sa" {
  depends_on = [ 
      aws_iam_role.csi_secrets_store_role,
      aws_iam_policy.csi_secrets_store_policy
  ]       
  metadata {
    name = "csi-secrets-store-driver-sa"
    namespace = "app"
    annotations = {
      "eks.amazonaws.com/role-arn" =  "${aws_iam_role.csi_secrets_store_role.arn}"
    }
  }
  
}
