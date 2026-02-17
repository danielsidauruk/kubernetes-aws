# --- Postgres Helm Release
resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.3.0"
  namespace  = var.namespace

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }

      # serviceAccount = {
      #   create = false
      #   name   = kubernetes_service_account.workload_identity.metadata[0].name
      # }

      auth = {
        username       = var.postgres_user
        database       = var.database_name
        existingSecret = var.secret_name
        # Use same password for all postgres user
        secretKeys = {
          adminPasswordKey       = var.secret_key
          userPasswordKey        = var.secret_key
          replicationPasswordKey = var.secret_key
        }
      }

      architecture = "replication"

      readReplicas = {
        replicaCount = 1
        persistence = {
          enabled      = true
          size         = "20Gi"
          storageClass = "gp3"
        }
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }

        # extendedConfiguration = {
        #   max_connections      = 200
        #   shared_buffers       = "256MB"
        #   effective_cache_size = "768MB"
        #   work_mem             = "4MB"
        #   maintenance_work_mem = "64MB"
        # }

      }

      primary = {
        persistence = {
          enabled      = true
          size         = "20Gi"
          storageClass = "gp3"
        }

        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }

        # extendedConfiguration = {
        #   max_connections      = 200
        #   shared_buffers       = "256MB"
        #   effective_cache_size = "768MB"
        #   work_mem             = "4MB"
        #   maintenance_work_mem = "64MB"
        # }

        # extraVolumes = [
        #   {
        #     name = "secrets-store-inline"
        #     csi = {
        #       driver   = "secrets-store.csi.k8s.io"
        #       readOnly = true
        #       volumeAttributes = {
        #         secretProviderClass = kubernetes_manifest.secret_provider_class.manifest.metadata.name
        #       }
        #     }
        #   }
        # ]

        # extraVolumeMounts = [
        #   {
        #     name      = "secrets-store-inline"
        #     mountPath = "/mnt/secrets-store"
        #     readOnly  = true
        #   }
        # ]
      }

      metrics = {
        enabled = true
        # serviceMonitor = {
        #   enabled   = true
        #   namespace = kubernetes_namespace.main.metadata[0].name
        #   interval  = "30s"
        # }
      }
    })
  ]

  depends_on = [
    # kubernetes_storage_class_v1.gp3,
    # kubernetes_manifest.secret_provider_class
  ]
}