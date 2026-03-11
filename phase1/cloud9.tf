resource "aws_security_group" "ssm_endpoints" {
  provider    = aws.east
  name        = "${var.cloud9_name}-ssm-endpoints"
  description = "Allow HTTPS from east VPC to SSM endpoints"
  vpc_id      = module.vpc_east.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.east_cidr]
  }

  tags = merge(local.all_tags, { Name = "${var.cloud9_name}-ssm-sg" })
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])
  provider = aws.east

  vpc_id              = module.vpc_east.vpc_id
  service_name        = "com.amazonaws.${var.region_east}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc_east.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoints.id]
  tags                = merge(local.all_tags, { Name = "${var.cloud9_name}-${each.key}" })
}

resource "aws_security_group" "cloud9" {
  provider    = aws.east
  name        = "${var.cloud9_name}-cloud9"
  description = "Cloud9 cross-VPC security group"
  vpc_id      = module.vpc_east.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.east_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.west_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.east_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.west_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.all_tags, { Name = "${var.cloud9_name}-cloud9-sg" })
}

resource "aws_cloud9_environment_ec2" "this" {
  provider                    = aws.east
  name                        = var.cloud9_name
  description                 = "multi-region demo workstation"
  instance_type               = var.cloud9_instance_type
  image_id                    = "amazonlinux-2023-x86_64"
  connection_type             = "CONNECT_SSM"
  subnet_id                   = module.vpc_east.private_subnet_ids[0]
  automatic_stop_time_minutes = 30
  owner_arn                   = var.cloud9_owner_arn

  tags = { for k, v in local.all_tags : k => v if k != "Name" }

  depends_on = [aws_vpc_endpoint.ssm]
}

resource "null_resource" "disable_managed_creds" {
  count = var.cloud9_disable_managed_creds ? 1 : 0

  provisioner "local-exec" {
    command = "aws cloud9 update-environment --environment-id ${aws_cloud9_environment_ec2.this.id} --managed-credentials-action DISABLE --region ${var.region_east}"
  }
  depends_on = [aws_cloud9_environment_ec2.this]
}

resource "time_sleep" "wait_for_cloud9_instance" {
  create_duration = "120s"
  depends_on      = [aws_cloud9_environment_ec2.this]
}

data "aws_instance" "cloud9" {
  provider = aws.east

  filter {
    name   = "tag:aws:cloud9:environment"
    values = [aws_cloud9_environment_ec2.this.id]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [time_sleep.wait_for_cloud9_instance]
}

resource "aws_network_interface_sg_attachment" "cloud9" {
  provider             = aws.east
  security_group_id    = aws_security_group.cloud9.id
  network_interface_id = data.aws_instance.cloud9.network_interface_id
}
