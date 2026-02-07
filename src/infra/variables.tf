variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to use."
  default     = 3
}

variable "primary_region" {
  type        = string
  description = "AWS Primary Region."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster Name."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account (IRSA)."
}

variable "kubernetes_group" {
  type        = string
  description = "Kubernetes Group for Console Access."
}

variable "eks_admin_arn" {
  type        = string
  description = "IAM User ARN to access Kubernetes & EKS cluster."
}

variable "secret_name" {
  type        = string
  description = "Secret name for PostgreSQL."
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username."
}

variable "database_name" {
  type        = string
  description = "Database name."
}
