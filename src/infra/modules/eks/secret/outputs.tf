output "secret_arn" {
  description = "Secret ARN."
  value       = aws_secretsmanager_secret.postgres.arn
}
