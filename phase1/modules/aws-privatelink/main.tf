terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
  }
}

locals {
  network_id = split(".", var.network_dns_domain)[0]
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_availability_zone" "this" {
  for_each = var.subnets
  zone_id  = each.key
}

resource "aws_security_group" "this" {
  name        = "ccloud-privatelink_${local.network_id}_${var.vpc_id}"
  description = "Confluent Cloud PrivateLink SG"
  vpc_id      = data.aws_vpc.this.id

  dynamic "ingress" {
    for_each = [80, 443, 9092]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.this.cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = data.aws_vpc.this.id
  service_name        = var.private_link_endpoint_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.this.id]
  subnet_ids          = values(var.subnets)
  private_dns_enabled = false
}

resource "aws_route53_zone" "this" {
  name = var.network_dns_domain
  vpc {
    vpc_id = data.aws_vpc.this.id
  }
}

locals {
  endpoint_prefix = split(".", aws_vpc_endpoint.this.dns_entry[0]["dns_name"])[0]
}

resource "aws_route53_record" "wildcard" {
  count   = length(var.subnets) == 1 ? 0 : 1
  zone_id = aws_route53_zone.this.zone_id
  name    = "*.${aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = var.dns_ttl
  records = [aws_vpc_endpoint.this.dns_entry[0]["dns_name"]]
}

resource "aws_route53_record" "zonal" {
  for_each = var.subnets
  zone_id  = aws_route53_zone.this.zone_id
  name     = length(var.subnets) == 1 ? "*" : "*.${each.key}"
  type     = "CNAME"
  ttl      = var.dns_ttl
  records = [
    format("%s-%s%s",
      local.endpoint_prefix,
      data.aws_availability_zone.this[each.key].name,
      replace(aws_vpc_endpoint.this.dns_entry[0]["dns_name"], local.endpoint_prefix, "")
    )
  ]
}

output "vpc_endpoint_id"   { value = aws_vpc_endpoint.this.id }
output "security_group_id" { value = aws_security_group.this.id }
output "route53_zone_id"   { value = aws_route53_zone.this.zone_id }
