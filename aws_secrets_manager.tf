######################################################################################
#1. Install AWS Secrets Manager using Helm Chart
######################################################################################

resource "helm_release" "aws_secrets_manager" {
  #atomic           = true
  force_update     = true
  name             = "aws-secrets-manager"
  chart            = "secrets-store-csi-driver-provider-aws"
  namespace        = "kube-system"
  repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  cleanup_on_fail  = true
  wait_for_jobs    = true

  # Ensure IAM role and service account exist before Helm install
  depends_on = [
    aws_iam_role.csi_secrets_store_role,
    aws_iam_policy.csi_secrets_store_policy
  ]
  
}
