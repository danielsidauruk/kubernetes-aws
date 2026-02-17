variable "namespace" {
  type        = string
  description = "Kubernetes Namespaces name."
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username."
}

variable "database_name" {
  type        = string
  description = "Database name."
}

variable "secret_name" {
  type        = string
  description = "PostgreSQL secret name."
}

variable "secret_key" {
  type        = string
  description = "PostgreSQL secret key."
}
