module "namespace" {
  source = "./modules/namespaces"

  namespace = var.namespace
}

module "app" {
  source = "./modules/app"

  namespace            = module.namespace.name
  secret_provider_name = module.secrets_csi.secret_provider_name

  project_name          = var.project_name
  database_name         = var.database_name
  postgres_user         = var.postgres_user
  secret_name           = var.secret_name
  secret_key            = var.secret_key
  service_account       = var.service_account
  workload_identity_arn = var.workload_identity_arn
  image                 = var.image

  depends_on = [module.secrets_csi]
}

module "ingress" {
  source = "./modules/ingress"

  app_service = module.app.service
  namespace   = module.namespace.name

  project_name       = var.project_name
  vpc_id             = var.vpc_id
  alb_controller_arn = var.alb_controller_arn
  cluster_name       = var.cluster_name
}

module "secrets_csi" {
  source = "./modules/secrets_csi"

  namespace = module.namespace.name

  secret_name           = var.secret_name
  secret_key            = var.secret_key
  service_account       = var.service_account
  workload_identity_arn = var.workload_identity_arn
}

module "rbac" {
  source = "./modules/rbac"

  kubernetes_group = var.kubernetes_group
}

module "postgres" {
  source = "./modules/postgres"

  namespace = module.namespace.name

  postgres_user = var.postgres_user
  database_name = var.database_name
  secret_name   = var.secret_name
  secret_key    = var.secret_key

  depends_on = [module.secrets_csi]
}

module "storage" {
  source = "./modules/storage"
}
