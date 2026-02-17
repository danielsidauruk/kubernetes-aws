variable "namespace" {
  type        = string
  description = "Kubernetes Namespaces name."
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account (IRSA)."
}

variable "workload_identity_arn" {
  type        = string
  description = "Workload Identity Role ARN."
}

variable "secret_name" {
  type        = string
  description = "PostgreSQL secret name."
}

variable "secret_key" {
  type        = string
  description = "PostgreSQL secret key."
}
