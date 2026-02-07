output "connect_to_eks" {
  description = "Command to Connect to EKS."
  value       = "aws eks update-kubeconfig --region ${var.primary_region} --name ${var.cluster_name}"
}

output "ingress_hostname" {
  description = "NLB Public Url."
  value       = module.kubernetes.ingress_hostname
}
