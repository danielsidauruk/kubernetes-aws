variable "namespace" {
  type        = string
  description = "Kubernetes Namespaces name."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account (IRSA)."
}

variable "workload_identity_arn" {
  type        = string
  description = "Kubernetes Workload Identity Service Account ARN."
}

variable "secret_name" {
  type        = string
  description = "PostgreSQL secret name."
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