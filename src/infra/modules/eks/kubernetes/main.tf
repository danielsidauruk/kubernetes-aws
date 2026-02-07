# --- Namespace ---
resource "kubernetes_namespace" "main" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

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

# --- Role Binding ---
resource "kubernetes_cluster_role" "eks_console_access" {
  metadata {
    name = "eks-console-access-clusterrole"
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "namespaces",
      "pods",
      "configmaps",
      "endpoints",
      "events",
      "limitranges",
      "persistentvolumeclaims",
      "podtemplates",
      "replicationcontrollers",
      "resourcequotas",
      "secrets",
      "serviceaccounts",
      "services"
    ]
    verbs = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["events.k8s.io"]
    resources  = ["events"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "ingresses", "networkpolicies", "replicasets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "roles"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csistoragecapacities"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "eks_console_access" {
  metadata {
    name = "eks-console-access-binding"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.eks_console_access.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = var.kubernetes_group # example: "eks-console-access-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

# --- AWS Secret Provider Helm Chart ---
resource "helm_release" "aws_secrets_provider" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  values = [
    yamlencode({
      secrets-store-csi-driver = {
        install = true

        syncSecret = {
          enabled = true
        }
      }
    })
  ]
}


# --- Secret Provider Class ---
locals {
  postgres_secret_key = "postgres-password"
}

resource "kubernetes_manifest" "secret_provider_class" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = "secret-provider-class"
      namespace = kubernetes_namespace.main.metadata[0].name
    }

    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName         = var.secret_name
            objectType         = "secretsmanager"
            objectVersionLabel = "AWSCURRENT"
          },
        ])
      }
      secretObjects = [
        {
          secretName = var.secret_name
          type       = "Opaque"
          data = [
            {
              key        = local.postgres_secret_key #"postgres-password"
              objectName = var.secret_name
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.aws_secrets_provider
  ]
}

# --- Config Map ---
resource "kubernetes_config_map" "main" {
  metadata {
    name      = "config"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      name = var.project_name
    }
  }

  data = {
    # Postgres
    "PGUSER"     = var.postgres_user
    "PGHOST"     = "postgres-postgresql"
    "PGDATABASE" = var.database_name
    "PGPORT"     = "5432"

    # Redis
    "REDIS_ENDPOINT" = "redis-endpoint-awokawok"
    "REDIS_PORT"     = "6379"
  }
}

# --- Deployment ---
resource "kubernetes_deployment" "main" {
  metadata {
    name      = var.project_name
    namespace = kubernetes_namespace.main.metadata[0].name
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
              "secretProviderClass" = kubernetes_manifest.secret_provider_class.manifest.metadata.name
            }
          }
        }

        container {
          image = "nginx"
          name  = "nginx-pod"

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
                key  = local.postgres_secret_key
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.postgres]
}

# --- Service ---
resource "kubernetes_service" "main" {
  metadata {
    name      = "app-service"
    namespace = kubernetes_namespace.main.metadata[0].name
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

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"

        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        }
      }
    })
  ]
}


resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.main.metadata[0].name

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.main.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]

}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}

# --- Kubernetes Storage Class gp3
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    fsType     = "ext4"
    iops       = "3000"
    throughput = "125"
  }
}

# --- Postgres Helm Release
resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.2.4"
  namespace  = kubernetes_namespace.main.metadata[0].name

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }

      auth = {
        username       = var.postgres_user
        database       = var.database_name
        existingSecret = var.secret_name

        secretKeys = {
          userPasswordKey = local.postgres_secret_key
        }
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
      }

      metrics = {
        enabled = false # true
      }
    })
  ]

  depends_on = [
    helm_release.aws_secrets_provider,
    kubernetes_manifest.secret_provider_class,
    kubernetes_storage_class_v1.gp3
  ]
}

# --- Redis Helm Release
# resource "helm_release" "redis" {
#   name       = "redis"
#   repository = "oci://registry-1.docker.io/bitnamicharts"
#   chart      = "redis"
#   version    = "19.5.1"

#   namespace = kubernetes_namespace.main.metadata[0].name

#   values = [
#     yamlencode({
#       architecture = "standalone"

#       auth = {
#         enabled        = true
#         existingSecret = var.redis_secret_name
#         existingSecretPasswordKey = "redis-password"
#       }

#       master = {
#         persistence = {
#           enabled      = true
#           size         = "8Gi"
#           storageClass = "gp3"
#         }
#       }

#       resources = {
#         requests = {
#           cpu    = "100m"
#           memory = "256Mi"
#         }
#         limits = {
#           cpu    = "500m"
#           memory = "512Mi"
#         }
#       }
#     })
#   ]

#   depends_on = [
#     helm_release.aws_secrets_provider,
#     kubernetes_manifest.secret_provider_class
#   ]
# }

