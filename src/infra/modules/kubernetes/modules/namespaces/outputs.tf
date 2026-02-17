output "name" {
  value = kubernetes_namespace.main.metadata[0].name
}