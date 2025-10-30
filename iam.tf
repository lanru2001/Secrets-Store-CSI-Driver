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
