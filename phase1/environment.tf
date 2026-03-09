data "confluent_organization" "current" {}

resource "confluent_environment" "main" {
  display_name = var.environment_name
}

resource "confluent_network" "east" {
  count            = local.is_private ? 1 : 0
  display_name     = "East PrivateLink Network"
  cloud            = "AWS"
  region           = var.region_east
  connection_types = ["PRIVATELINK"]
  zones            = var.zones_east
  environment {
    id = confluent_environment.main.id
  }
}

resource "confluent_network" "west" {
  count            = local.is_private ? 1 : 0
  display_name     = "West PrivateLink Network"
  cloud            = "AWS"
  region           = var.region_west
  connection_types = ["PRIVATELINK"]
  zones            = var.zones_west
  environment {
    id = confluent_environment.main.id
  }
}

resource "confluent_private_link_access" "east" {
  count        = local.is_private ? 1 : 0
  display_name = "PrivateLink Access East"
  aws {
    account = var.aws_account_id
  }
  environment {
    id = confluent_environment.main.id
  }
  network {
    id = confluent_network.east[0].id
  }
}

resource "confluent_private_link_access" "west" {
  count        = local.is_private ? 1 : 0
  display_name = "PrivateLink Access West"
  aws {
    account = var.aws_account_id
  }
  environment {
    id = confluent_environment.main.id
  }
  network {
    id = confluent_network.west[0].id
  }
}
