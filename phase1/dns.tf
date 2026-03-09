resource "aws_route53_zone_association" "west_zone_to_east_vpc" {
  count      = local.is_private ? 1 : 0
  provider   = aws.east
  zone_id    = module.privatelink_west[0].route53_zone_id
  vpc_id     = module.vpc_east.vpc_id
  vpc_region = var.region_east
}

resource "aws_route53_zone_association" "east_zone_to_west_vpc" {
  count      = local.is_private ? 1 : 0
  provider   = aws.west
  zone_id    = module.privatelink_east[0].route53_zone_id
  vpc_id     = module.vpc_west.vpc_id
  vpc_region = var.region_west
}

resource "aws_route53_zone_association" "extra_west_zones" {
  provider = aws.east
  count    = length(var.west_private_hosted_zone_ids)
  zone_id  = var.west_private_hosted_zone_ids[count.index]
  vpc_id   = module.vpc_east.vpc_id
}
