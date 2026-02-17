variable "namespace" {
  type        = string
  description = "Kubernetes Namespaces name."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster Name."
}

variable "alb_controller_arn" {
  type        = string
  description = "ALB Controller Role ARN."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "app_service" {
  type        = string
  description = "Applicaiton service."
}
