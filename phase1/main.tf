module "vpc_east" {
  source    = "./modules/vpc"
  providers = { aws = aws.east }

  name            = var.vpc_name_east
  cidr            = local.east_cidr
  azs             = local.east_azs
  public_subnets  = local.east_public_subnets
  private_subnets = local.east_private_subnets
  tags            = local.all_tags
}

module "vpc_west" {
  source    = "./modules/vpc"
  providers = { aws = aws.west }

  name            = var.vpc_name_west
  cidr            = local.west_cidr
  azs             = local.west_azs
  public_subnets  = local.west_public_subnets
  private_subnets = local.west_private_subnets
  tags            = local.all_tags
}
