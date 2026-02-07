variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block."
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster Name."
}

variable "namespace" {
  type        = string
  description = "Kubernetes Namespace."
}

variable "service_account" {
  type        = string
  description = "Kubernetes Service Account (IRSA)."
}

variable "kubernetes_group" {
  type        = string
  description = "Kubernetes Group for Console Access."
}

variable "eks_admin_arn" {
  type        = string
  description = "IAM User ARN to access Kubernetes & EKS cluster."
}

variable "secret_arn" {
  type        = string
  description = "Secret ARN."
}
