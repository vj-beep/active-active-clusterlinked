output "vpc_id_east"                { value = module.vpc_east.vpc_id }
output "vpc_id_west"                { value = module.vpc_west.vpc_id }
output "subnets_to_privatelink_east" { value = module.vpc_east.subnets_to_privatelink }
output "subnets_to_privatelink_west" { value = module.vpc_west.subnets_to_privatelink }
output "peering_connection_id"       { value = aws_vpc_peering_connection.east_to_west.id }

output "cloud9_environment_id" { value = aws_cloud9_environment_ec2.this.id }
output "cloud9_url" {
  value = "https://${var.region_east}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.this.id}"
}

output "confluent_environment_id" { value = confluent_environment.main.id }
output "east_cluster_id"          { value = confluent_kafka_cluster.east.id }
output "west_cluster_id"          { value = confluent_kafka_cluster.west.id }
output "east_rest_endpoint"       { value = confluent_kafka_cluster.east.rest_endpoint }
output "west_rest_endpoint"       { value = confluent_kafka_cluster.west.rest_endpoint }
output "east_bootstrap_endpoint"  { value = confluent_kafka_cluster.east.bootstrap_endpoint }
output "west_bootstrap_endpoint"  { value = confluent_kafka_cluster.west.bootstrap_endpoint }

output "manager_east_api_key"    { value = confluent_api_key.manager_east.id }
output "manager_east_api_secret" {
  value     = confluent_api_key.manager_east.secret
  sensitive = true
}
output "manager_west_api_key"    { value = confluent_api_key.manager_west.id }
output "manager_west_api_secret" {
  value     = confluent_api_key.manager_west.secret
  sensitive = true
}

output "svc_link_east_api_key" {
  value = local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].id : ""
}
output "svc_link_east_api_secret" {
  value     = local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].secret : ""
  sensitive = true
}
output "svc_link_west_api_key" {
  value = local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].id : ""
}
output "svc_link_west_api_secret" {
  value     = local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].secret : ""
  sensitive = true
}

output "phase2_tfvars" {
  description = "Run: terraform output -raw phase2_tfvars > ../phase2/terraform.tfvars"
  sensitive   = true
  value = <<-TFVARS
confluent_cloud_api_key    = "${var.confluent_cloud_api_key}"
confluent_cloud_api_secret = "${var.confluent_cloud_api_secret}"

environment_id = "${confluent_environment.main.id}"

east_cluster_id         = "${confluent_kafka_cluster.east.id}"
east_rest_endpoint      = "${confluent_kafka_cluster.east.rest_endpoint}"
east_bootstrap_endpoint = "${confluent_kafka_cluster.east.bootstrap_endpoint}"

west_cluster_id         = "${confluent_kafka_cluster.west.id}"
west_rest_endpoint      = "${confluent_kafka_cluster.west.rest_endpoint}"
west_bootstrap_endpoint = "${confluent_kafka_cluster.west.bootstrap_endpoint}"

manager_east_key    = "${confluent_api_key.manager_east.id}"
manager_east_secret = "${confluent_api_key.manager_east.secret}"
manager_west_key    = "${confluent_api_key.manager_west.id}"
manager_west_secret = "${confluent_api_key.manager_west.secret}"

svc_link_east_key    = "${local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].id : ""}"
svc_link_east_secret = "${local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].secret : ""}"
svc_link_west_key    = "${local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].id : ""}"
svc_link_west_secret = "${local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].secret : ""}"

topic_name_east    = "${var.topic_name_east}"
topic_name_west    = "${var.topic_name_west}"
topic_partitions   = ${var.topic_partitions}

supports_cluster_linking = ${local.supports_cluster_linking}
TFVARS
}

output "next_steps" {
  value = <<-STEPS

  ============================================
  PHASE 1 COMPLETE
  ============================================

  Next steps:

  1. Open Cloud9:
     ${local.is_private ? "https://${var.region_east}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.this.id}" : "N/A"}

  2. In Cloud9, install Terraform:
     sudo yum install -y yum-utils
     sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
     sudo yum -y install terraform

  3. Clone repo and generate phase2 tfvars:
     git clone git@github.com:vj-beep/CFLT-Terraform.git
     cd CFLT-Terraform/phase1
     # Copy terraform.tfvars from your laptop to here
     terraform init
     terraform output -raw phase2_tfvars > ../phase2/terraform.tfvars

  4. Run phase2:
     cd ../phase2
     terraform init
     terraform apply

  STEPS
}
