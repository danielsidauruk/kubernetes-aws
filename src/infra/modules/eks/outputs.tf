output "workload_identity_arn" {
  description = "Workload Identity Role ARN."
  value       = aws_iam_role.workload_identity.arn
}

output "alb_controller_arn" {
  description = "ALB Controller Role ARN."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "cluster_name" {
  description = "EKS Cluster Name."
  value       = aws_eks_cluster.eks_cluster.name
}
