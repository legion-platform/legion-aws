########################################################
# Networking
########################################################
module "vpc" {
  source               = "../../../../modules/aws/networking/vpc"
  cluster_name         = var.cluster_name
  cidr                 = var.cidr
  az_list              = var.az_list
  nat_subnet_cidr      = var.nat_subnet_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "firewall" {
  source       = "../../../../modules/aws/networking/firewall"
  allowed_ips  = var.allowed_ips
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  vpc_sg_id    = module.vpc.vpc_sg_id
}

module "iam" {
  source       = "../../../../modules/aws/iam"
  cluster_name = var.cluster_name
}

module "eks" {
  source                     = "../../../../modules/aws/eks_cluster"
  allowed_ips                = var.allowed_ips
  k8s_version                = var.k8s_version
  cluster_name               = var.cluster_name
  vpc_id                     = module.vpc.vpc_id
  master_role_arn            = module.iam.master_role_arn
  master_sg_id               = module.firewall.master_sg_id
  node_role_arn              = module.iam.node_role_arn
  node_sg_id                 = module.firewall.node_sg_id
  node_instance_profile_name = module.iam.node_instance_profile_name
  bastion_sg_id              = module.firewall.bastion_sg_id
  subnet_ids                 = module.vpc.private_subnet_ids
  nat_subnet_id              = module.vpc.nat_subnet_id
  aws_region                 = var.region_aws
}
