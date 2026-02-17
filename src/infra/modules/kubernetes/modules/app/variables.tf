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
  description = "Workload Identity Role ARN."
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username."
}

variable "database_name" {
  type        = string
  description = "Database name."
}

variable "image" {
  type        = string
  description = "Container Image name."
}

variable "secret_name" {
  type        = string
  description = "Secret name."
}

variable "secret_key" {
  type        = string
  description = "Secret key."
}

variable "secret_provider_name" {
  type        = string
  description = "Kubernetes Secret Provider Class Name."
}