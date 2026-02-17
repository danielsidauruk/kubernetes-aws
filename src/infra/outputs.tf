output "connect_to_eks" {
  description = "Command to Connect to EKS."
  value       = "aws eks update-kubeconfig --region ${var.primary_region} --name ${var.cluster_name}"
}

output "app_ingress" {
  description = "Application ALB Url."
  value       = module.kubernetes.app_ingress
}
