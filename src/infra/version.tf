terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.2"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.primary_region
}

# For local development
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# # Using S3 as the Terraform Backend (Recommended)
# terraform {
#   backend "s3" {
#     bucket = "<your bucket>"         # S3 bucket to store the state
#     key    = "eks/terraform.tfstate" # Path inside the bucket
#     region = "<availability-zone>"   # AWS region (e.g., "us-east-1")
#   }
# }

data "aws_eks_cluster" "main" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "main" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
