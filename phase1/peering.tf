resource "aws_vpc_peering_connection" "east_to_west" {
  provider    = aws.east
  vpc_id      = module.vpc_east.vpc_id
  peer_vpc_id = module.vpc_west.vpc_id
  peer_region = var.region_west
  tags        = merge(local.all_tags, { Name = "east-to-west-peering" })
}

resource "aws_vpc_peering_connection_accepter" "west" {
  provider                  = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  auto_accept               = true
  tags                      = merge(local.all_tags, { Name = "east-to-west-peering" })
}

resource "aws_vpc_peering_connection_options" "east" {
  provider                  = aws.east
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  depends_on = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_vpc_peering_connection_options" "west" {
  provider                  = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  depends_on = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_route" "east_public_to_west" {
  provider                  = aws.east
  route_table_id            = module.vpc_east.public_route_table_id
  destination_cidr_block    = local.west_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  depends_on                = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_route" "east_private_to_west" {
  provider                  = aws.east
  route_table_id            = module.vpc_east.private_route_table_id
  destination_cidr_block    = local.west_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  depends_on                = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_route" "west_public_to_east" {
  provider                  = aws.west
  route_table_id            = module.vpc_west.public_route_table_id
  destination_cidr_block    = local.east_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  depends_on                = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_route" "west_private_to_east" {
  provider                  = aws.west
  route_table_id            = module.vpc_west.private_route_table_id
  destination_cidr_block    = local.east_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.east_to_west.id
  depends_on                = [aws_vpc_peering_connection_accepter.west]
}

resource "aws_security_group_rule" "west_pl_https_from_east" {
  count             = local.is_private ? 1 : 0
  provider          = aws.west
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [local.east_cidr]
  security_group_id = module.privatelink_west[0].security_group_id
  description       = "HTTPS from east VPC via peering"
}

resource "aws_security_group_rule" "west_pl_kafka_from_east" {
  count             = local.is_private ? 1 : 0
  provider          = aws.west
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = [local.east_cidr]
  security_group_id = module.privatelink_west[0].security_group_id
  description       = "Kafka from east VPC via peering"
}
