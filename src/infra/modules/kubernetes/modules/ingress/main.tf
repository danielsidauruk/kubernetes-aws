# --- ALB Controller Helm Release ---
resource "helm_release" "alb_controller" {
  name       = "alb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.0.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      vpcId       = var.vpc_id
      clusterName = var.cluster_name

      serviceAccount = {
        create = true
        name   = "alb-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.alb_controller_arn
        }
      }
    })
  ]
}


# --- Kubernetes Ingress ---
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "${var.project_name}-ingress"
    namespace = var.namespace

    annotations = {
      "kubernetes.io/ingress.class"            = "alb"
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
      # "alb.ingress.kubernetes.io/group.name"   = "monitoring"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = var.app_service # kubernetes_service.main.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true

  depends_on = [helm_release.alb_controller]

}

data "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = kubernetes_ingress_v1.ingress.metadata[0].name
    namespace = var.namespace
  }
}
