resource "confluent_service_account" "svc_link" {
  count        = local.supports_cluster_linking ? 1 : 0
  display_name = "vj-aa-svc-link"
  description  = "Cluster link management"
}

resource "confluent_service_account" "app_manager" {
  display_name = "vj-aa-app-manager"
  description  = "Topic and cluster management"
}

resource "confluent_service_account" "app_producer" {
  display_name = "vj-aa-app-producer"
  description  = "Producer service account"
}

resource "confluent_service_account" "app_consumer" {
  display_name = "vj-aa-app-consumer"
  description  = "Consumer service account"
}

resource "confluent_role_binding" "svc_link_env_admin" {
  count       = local.supports_cluster_linking ? 1 : 0
  principal   = "User:${confluent_service_account.svc_link[0].id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.main.resource_name
}

resource "confluent_role_binding" "app_manager_east" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.east.rbac_crn
}

resource "confluent_role_binding" "app_manager_west" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.west.rbac_crn
}

resource "confluent_role_binding" "producer_east" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.east.rbac_crn}/kafka=${confluent_kafka_cluster.east.id}/topic=${var.topic_name_east}"
}

resource "confluent_role_binding" "producer_west" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.west.rbac_crn}/kafka=${confluent_kafka_cluster.west.id}/topic=${var.topic_name_west}"
}

resource "confluent_role_binding" "consumer_east_topic" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.east.rbac_crn}/kafka=${confluent_kafka_cluster.east.id}/topic=${var.topic_name_east}"
}

resource "confluent_role_binding" "consumer_east_group" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.east.rbac_crn}/kafka=${confluent_kafka_cluster.east.id}/group=${var.consumer_group_prefix}"
}

resource "confluent_role_binding" "consumer_west_topic" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.west.rbac_crn}/kafka=${confluent_kafka_cluster.west.id}/topic=${var.topic_name_west}"
}

resource "confluent_role_binding" "consumer_west_group" {
  count       = local.supports_granular_rbac ? 1 : 0
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.west.rbac_crn}/kafka=${confluent_kafka_cluster.west.id}/group=${var.consumer_group_prefix}"
}

resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"
  depends_on = [
    confluent_role_binding.app_manager_east,
    confluent_role_binding.app_manager_west,
    confluent_role_binding.svc_link_env_admin,
  ]
}
