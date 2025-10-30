# Secrets-Store-CSI-Driver
Use Secrets Store CSI Driver to pull secrets from AWS Secrets Manager

Secrets Store CSI Driver Workflow
Below is the diagrammatic workflow of the Secret Stores CSI Driver, which gets secrets from the AWS Secrets Manager and mounts them in a pod.

https://devopscube.com/content/images/2025/03/secret-store-csi-driver_2-1.jpg

How it works?
1. The pod initiates the process by defining the SecretProviderClass object and uses a service account with the necessary permissions to authenticate Secrets Manager.
2. The SecretProviderClass object contains the details of the secret stored in secrets manager..
3. The CSI driver uses the secret details on SecretProviderClass to fetch the secret from the external secret store and mounts it inside the pod as a file.

Step 1: Create an IAM Policy
```bash
resource "aws_iam_role" "csi_secrets_store_role" {
  name = "CsiSecretsStoreRole"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer}"
                },
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        "${local.oidc_issuer}:sub": "system:serviceaccount:app:csi-secrets-store-driver-sa",
                        "${local.oidc_issuer}:aud": "sts.amazonaws.com"
                    }
                }
            }
        ]
    }    
  )
  
  tags = {
    Name = "CsiSecretsStoreRole"
  }
}

resource "aws_iam_policy" "csi_secrets_store_policy" {
  name = "CsiSecretsStorePolicy"
  path        = "/"
  description = "csi secrets store policy"

  policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {   
                "Sid": "AllowAccessToSecretsManager",
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ],
                "Resource": [
                    "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${var.secret_name}*",
                    "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:app-postgres-secret*"

                ]
            }
        ]
    }
  )  
}

resource "aws_iam_role_policy_attachment" "csi_secrets_store_policy_attach" {
  role       = aws_iam_role.csi_secrets_store_role.name
  policy_arn = aws_iam_policy.csi_secrets_store_policy.arn
}
```
Step 2: Install CSI Driver and AWS Provider
```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
```
Step 3: Create a Service Account
```bash
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
```
