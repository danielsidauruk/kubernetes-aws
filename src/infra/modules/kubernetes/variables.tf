variable "namespace" {
  type        = string
  description = "Kubernetes Namespaces name."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "image" {
  type        = string
  description = "Container Image name."
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account (IRSA)."
}

variable "alb_controller_sa" {
  type        = string
  description = "ALB Controller service account name."
}

variable "workload_identity_arn" {
  type        = string
  description = "Workload Identity Role ARN."
}

variable "alb_controller_arn" {
  type        = string
  description = "ALB Controller Role ARN."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster Name."
}

variable "secret_name" {
  type        = string
  description = "secret name."
}

variable "secret_key" {
  type        = string
  description = "secret key."
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username."
}

variable "database_name" {
  type        = string
  description = "Database name."
}

variable "kubernetes_group" {
  type        = string
  description = "Kubernetes Group for Console Access."
}
