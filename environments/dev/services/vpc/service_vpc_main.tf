module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = var.vpc_name
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  environment          = local.environment
  owner                = local.owner
  tags                 = merge(local.common_tags, var.tags)
}
