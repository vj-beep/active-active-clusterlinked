locals {
  all_tags = {
    Project   = var.vpc_tag
    ManagedBy = "terraform"
  }

  east_cidr = "10.0.0.0/16"
  west_cidr = "10.1.0.0/16"

  east_azs = ["${var.region_east}a", "${var.region_east}b", "${var.region_east}c"]
  west_azs = ["${var.region_west}a", "${var.region_west}b", "${var.region_west}c"]

  east_public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  east_private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  west_public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  west_private_subnets = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]

  is_basic      = var.cluster_type == "BASIC"
  is_standard   = var.cluster_type == "STANDARD"
  is_dedicated  = var.cluster_type == "DEDICATED"
  is_enterprise = var.cluster_type == "ENTERPRISE"

  is_private               = local.is_dedicated || local.is_enterprise
  supports_cluster_linking = local.is_private
  supports_network_links   = local.is_private
  supports_granular_rbac   = !local.is_basic
}
