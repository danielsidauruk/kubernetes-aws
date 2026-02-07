output "workload_identity_arn" {
  description = "Workload Identity Role ARN."
  value       = aws_iam_role.workload_identity.arn
}

