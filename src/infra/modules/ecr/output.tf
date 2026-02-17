output "ecr_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.main.arn
}
