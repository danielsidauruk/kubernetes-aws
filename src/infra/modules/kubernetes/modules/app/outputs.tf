output "service" {
  value = kubernetes_service.main.metadata[0].name
}