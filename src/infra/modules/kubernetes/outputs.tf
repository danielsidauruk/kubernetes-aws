output "app_ingress" {
  description = "Application ALB Url."
  value       = module.ingress.hostname
}
