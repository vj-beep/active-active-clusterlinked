output "vpc_id_east" {
  value = module.vpc_east.vpc_id
}

output "vpc_id_west" {
  value = module.vpc_west.vpc_id
}

output "subnets_to_privatelink_east" {
  value = module.vpc_east.subnets_to_privatelink
}

output "subnets_to_privatelink_west" {
  value = module.vpc_west.subnets_to_privatelink
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.east_to_west.id
}

output "cloud9_environment_id" {
  value = aws_cloud9_environment_ec2.this.id
}

output "cloud9_url" {
  value = "https://${var.region_east}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.this.id}"
}

output "confluent_environment_id" {
  value = confluent_environment.main.id
}

output "east_cluster_id" {
  value = confluent_kafka_cluster.east.id
}

output "west_cluster_id" {
  value = confluent_kafka_cluster.west.id
}

output "east_rest_endpoint" {
  value = confluent_kafka_cluster.east.rest_endpoint
}

output "west_rest_endpoint" {
  value = confluent_kafka_cluster.west.rest_endpoint
}

output "east_bootstrap_endpoint" {
  value = confluent_kafka_cluster.east.bootstrap_endpoint
}

output "west_bootstrap_endpoint" {
  value = confluent_kafka_cluster.west.bootstrap_endpoint
}

output "manager_east_api_key" {
  value = confluent_api_key.manager_east.id
}

output "manager_east_api_secret" {
  value     = confluent_api_key.manager_east.secret
  sensitive = true
}

output "manager_west_api_key" {
  value = confluent_api_key.manager_west.id
}

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

output "phase2_env" {
  description = "Run: terraform output -raw phase2_env > ../scripts/phase2.env"
  sensitive   = true
  value = <<-ENVFILE
ENV_ID="${confluent_environment.main.id}"
EAST_CLUSTER_ID="${confluent_kafka_cluster.east.id}"
WEST_CLUSTER_ID="${confluent_kafka_cluster.west.id}"
EAST_REST_ENDPOINT="${confluent_kafka_cluster.east.rest_endpoint}"
WEST_REST_ENDPOINT="${confluent_kafka_cluster.west.rest_endpoint}"
EAST_BOOTSTRAP="${confluent_kafka_cluster.east.bootstrap_endpoint}"
WEST_BOOTSTRAP="${confluent_kafka_cluster.west.bootstrap_endpoint}"
MANAGER_EAST_KEY="${confluent_api_key.manager_east.id}"
MANAGER_EAST_SECRET="${confluent_api_key.manager_east.secret}"
MANAGER_WEST_KEY="${confluent_api_key.manager_west.id}"
MANAGER_WEST_SECRET="${confluent_api_key.manager_west.secret}"
SVC_LINK_EAST_KEY="${local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].id : ""}"
SVC_LINK_EAST_SECRET="${local.supports_cluster_linking ? confluent_api_key.svc_link_east[0].secret : ""}"
SVC_LINK_WEST_KEY="${local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].id : ""}"
SVC_LINK_WEST_SECRET="${local.supports_cluster_linking ? confluent_api_key.svc_link_west[0].secret : ""}"
ENVFILE
}
