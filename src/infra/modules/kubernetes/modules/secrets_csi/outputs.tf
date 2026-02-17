output "secret_provider_name" {
  value = kubernetes_manifest.secret_provider_class.manifest.metadata.name
}
