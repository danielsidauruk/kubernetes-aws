# --- Service Account ---
resource "kubernetes_service_account" "workload_identity" {
  metadata {
    name      = var.service_account
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.workload_identity_arn
    }
  }
}

# --- Config Map ---
resource "kubernetes_config_map" "main" {
  metadata {
    name      = "config"
    namespace = var.namespace
    labels = {
      name = var.project_name
    }
  }

  data = {
    "POSTGRES_WRITE_HOST" = "postgres-postgresql-primary"
    "POSTGRES_READ_HOST"  = "postgres-postgresql-read"
    "POSTGRES_USER"       = var.postgres_user
    "POSTGRES_DB"         = var.database_name
    "POSTGRES_PORT"       = "5432"
  }
}

# --- Deployment ---
resource "kubernetes_deployment" "main" {
  metadata {
    name      = "${var.project_name}-deployment"
    namespace = var.namespace
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        name = var.project_name
      }
    }

    template {
      metadata {
        labels = {
          name = var.project_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.workload_identity.metadata[0].name

        volume {
          name = "secrets-store-inline"
          csi {
            driver    = "secrets-store.csi.k8s.io"
            read_only = true
            volume_attributes = {
              "secretProviderClass" = var.secret_provider_name
            }
          }
        }

        container {
          image = var.image
          name  = var.project_name

          port {
            container_port = 80
          }

          volume_mount {
            name       = "secrets-store-inline"
            mount_path = "/mnt/secrets-store"
            read_only  = true
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.main.metadata[0].name
            }
          }

          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = var.secret_key
              }
            }
          }
        }
      }
    }
  }
}

# --- Service ---
resource "kubernetes_service" "main" {
  metadata {
    name      = "${var.project_name}-service"
    namespace = var.namespace
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 80
      target_port = 80
    }
    selector = {
      name = var.project_name
    }
  }
}

# resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
#   metadata {
#     name      = var.project_name
#     namespace = var.namespace
#   }

#   spec {
#     min_replicas = 1
#     max_replicas = 5

#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = kubernetes_deployment.main.metadata[0].name
#     }

#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type               = "Utilization"
#           average_utilization = 70
#         }
#       }
#     }
#   }
# }
