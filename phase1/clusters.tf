data "aws_availability_zone" "east" {
  provider = aws.east
  for_each = toset(local.east_azs)
  name     = each.key
}

data "aws_availability_zone" "west" {
  provider = aws.west
  for_each = toset(local.west_azs)
  name     = each.key
}

locals {
  east_privatelink_subnets = {
    for i, az in local.east_azs :
    data.aws_availability_zone.east[az].zone_id => module.vpc_east.private_subnet_ids[i]
  }
  west_privatelink_subnets = {
    for i, az in local.west_azs :
    data.aws_availability_zone.west[az].zone_id => module.vpc_west.private_subnet_ids[i]
  }
}

resource "confluent_kafka_cluster" "east" {
  display_name = var.cluster_name_east
  availability = var.cluster_availability
  cloud        = "AWS"
  region       = var.region_east

  dynamic "basic" {
    for_each = local.is_basic ? [1] : []
    content {}
  }

  dynamic "standard" {
    for_each = local.is_standard ? [1] : []
    content {}
  }

  dynamic "dedicated" {
    for_each = local.is_dedicated ? [1] : []
    content {
      cku = var.cluster_cku
    }
  }

  dynamic "enterprise" {
    for_each = local.is_enterprise ? [1] : []
    content {}
  }

  environment {
    id = confluent_environment.main.id
  }

  dynamic "network" {
    for_each = local.is_private ? [1] : []
    content {
      id = confluent_network.east[0].id
    }
  }

  depends_on = [confluent_private_link_access.east]
}

resource "confluent_kafka_cluster" "west" {
  display_name = var.cluster_name_west
  availability = var.cluster_availability
  cloud        = "AWS"
  region       = var.region_west

  dynamic "basic" {
    for_each = local.is_basic ? [1] : []
    content {}
  }

  dynamic "standard" {
    for_each = local.is_standard ? [1] : []
    content {}
  }

  dynamic "dedicated" {
    for_each = local.is_dedicated ? [1] : []
    content {
      cku = var.cluster_cku
    }
  }

  dynamic "enterprise" {
    for_each = local.is_enterprise ? [1] : []
    content {}
  }

  environment {
    id = confluent_environment.main.id
  }

  dynamic "network" {
    for_each = local.is_private ? [1] : []
    content {
      id = confluent_network.west[0].id
    }
  }

  depends_on = [confluent_private_link_access.west]
}

module "privatelink_east" {
  count     = local.is_private ? 1 : 0
  source    = "./modules/aws-privatelink"
  providers = { aws = aws.east }

  network_dns_domain            = confluent_network.east[0].dns_domain
  private_link_endpoint_service = confluent_network.east[0].aws[0].private_link_endpoint_service
  vpc_id                        = module.vpc_east.vpc_id
  subnets                       = local.east_privatelink_subnets
  dns_ttl                       = var.dns_ttl

  depends_on = [confluent_private_link_access.east]
}

module "privatelink_west" {
  count     = local.is_private ? 1 : 0
  source    = "./modules/aws-privatelink"
  providers = { aws = aws.west }

  network_dns_domain            = confluent_network.west[0].dns_domain
  private_link_endpoint_service = confluent_network.west[0].aws[0].private_link_endpoint_service
  vpc_id                        = module.vpc_west.vpc_id
  subnets                       = local.west_privatelink_subnets
  dns_ttl                       = var.dns_ttl

  depends_on = [confluent_private_link_access.west]
}
