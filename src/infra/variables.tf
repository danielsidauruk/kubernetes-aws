variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.0.0/16"
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
  default     = "myapp-cluster"
}

variable "project_name" {
  type        = string
  description = "The name of the project."
  default     = "myapp"
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account (IRSA)."
  default     = "myapp-sa"
}

variable "alb_controller_sa" {
  type        = string
  description = "ALB Controller service account name."
  default     = "alb-controller"
}

variable "kubernetes_group" {
  type        = string
  description = "Kubernetes Group for Console Access."
  default     = "eks-console-access-group"
}

variable "eks_admin_arn" {
  type        = string
  description = "IAM User ARN to access Kubernetes & EKS cluster."
  default     = ""
}

variable "image" {
  type        = string
  description = "Container Image name."
  default     = "nginx"
}

variable "secret_name" {
  type        = string
  description = "Secret name for PostgreSQL."
  default     = "mysecretname"
}

variable "secret_key" {
  type        = string
  description = "PostgreSQL secret key."
  default     = "mysecretkey"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username."
  default     = "myuser"
}

variable "database_name" {
  type        = string
  description = "Database name."
  default     = "mydatabase"
}
