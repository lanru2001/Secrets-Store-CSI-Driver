# S3 remote state

terraform {
  backend "s3" {
    bucket         = "tf-remote-dev-bkt"
    key            = "project/secrets_store_csi_driver"
    region         = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.12"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "3.1.0"
    }
  }
}


data "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
}

#Get caller identity 
data "aws_caller_identity" "current" {}

locals {
  oidc_issuer = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
}

######################################################################################
#K8S and Helm Provider
######################################################################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = [ "eks", "get-token", "--cluster-name", "test", "--region",  "us-east-1" ]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = [ "eks", "get-token", "--cluster-name", "test", "--region",  "us-east-1" ]
      command     = "aws"
    }
  }
}

provider "kubectl" {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = [ "eks", "get-token", "--cluster-name", "test", "--region",  "us-east-1" ]
      command     = "aws"
    }
}

provider "aws" {
  region = "us-east-1"
}
