module "network" {
  source = "./modules/network"

  cidr_block     = var.cidr_block
  az_count       = var.az_count
  primary_region = var.primary_region
}

module "secret" {
  source = "./modules/secret"

  secret_name = var.secret_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "eks" {
  source = "./modules/eks"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  secret_arn         = module.secret.secret_arn
  cidr_block         = var.cidr_block
  cluster_name       = var.cluster_name
  namespace          = var.project_name # Use project_name as Namespace
  service_account    = var.service_account
  kubernetes_group   = var.kubernetes_group
  eks_admin_arn      = var.eks_admin_arn
  alb_controller_sa  = var.alb_controller_sa

  depends_on = [
    module.network,
    module.ecr,
    module.secret
  ]
}

module "kubernetes" {
  source = "./modules/kubernetes"

  vpc_id                = module.network.vpc_id
  workload_identity_arn = module.eks.workload_identity_arn
  alb_controller_arn    = module.eks.alb_controller_arn
  namespace             = var.project_name # Use project_name as Namespace
  project_name          = var.project_name
  cluster_name          = module.eks.cluster_name
  image                 = var.image
  kubernetes_group      = var.kubernetes_group
  service_account       = var.service_account
  alb_controller_sa     = var.alb_controller_sa
  secret_name           = var.secret_name
  secret_key            = var.secret_key
  postgres_user         = var.postgres_user
  database_name         = var.database_name

  depends_on = [
    module.eks,
    module.secret,
    module.ecr
  ]
}
