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


resource "kubernetes_manifest" "secret_provider_class" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = "secret-provider-class"
      namespace = var.namespace
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
              key        = var.secret_key
              objectName = var.secret_name
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.aws_secrets_provider,
  ]
}
