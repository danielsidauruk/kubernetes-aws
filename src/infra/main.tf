
module "eks-network" {
  source = "./modules/eks/network"

  cidr_block     = var.cidr_block
  az_count       = var.az_count
  primary_region = var.primary_region
}

module "eks" {
  source = "./modules/eks/eks"

  vpc_id             = module.eks-network.vpc_id
  private_subnet_ids = module.eks-network.private_subnet_ids
  secret_arn         = module.secret.secret_arn
  cidr_block         = var.cidr_block
  cluster_name       = var.cluster_name
  namespace          = var.project_name # Use project_name as Namespace
  service_account    = var.service_account
  kubernetes_group   = var.kubernetes_group
  eks_admin_arn      = var.eks_admin_arn

  depends_on = [module.eks-network]
}

module "secret" {
  source = "./modules/eks/secret"

  secret_name = var.secret_name
}

module "kubernetes" {
  source = "./modules/eks/kubernetes"

  workload_identity_arn = module.eks.workload_identity_arn
  namespace             = var.project_name # Use project_name as Namespace
  project_name          = var.project_name
  kubernetes_group      = var.kubernetes_group
  service_account       = var.service_account
  secret_name           = var.secret_name
  postgres_user         = var.postgres_user
  database_name         = var.database_name

  depends_on = [module.eks]
}