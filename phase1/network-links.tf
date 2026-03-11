resource "confluent_network_link_service" "east" {
  count        = local.supports_network_links ? 1 : 0
  display_name = "network-link-service-east"
  environment { id = confluent_environment.main.id }
  network     { id = confluent_network.east[0].id }
  accept { networks = [confluent_network.west[0].id] }
}

resource "confluent_network_link_endpoint" "west_to_east" {
  count        = local.supports_network_links ? 1 : 0
  display_name = "network-link-endpoint-west"
  environment { id = confluent_environment.main.id }
  network     { id = confluent_network.west[0].id }
  network_link_service { id = confluent_network_link_service.east[0].id }
  depends_on = [confluent_kafka_cluster.east, confluent_kafka_cluster.west]
}

resource "confluent_network_link_service" "west" {
  count        = local.supports_network_links ? 1 : 0
  display_name = "network-link-service-west"
  environment { id = confluent_environment.main.id }
  network     { id = confluent_network.west[0].id }
  accept { networks = [confluent_network.east[0].id] }
}

resource "confluent_network_link_endpoint" "east_to_west" {
  count        = local.supports_network_links ? 1 : 0
  display_name = "network-link-endpoint-east"
  environment { id = confluent_environment.main.id }
  network     { id = confluent_network.east[0].id }
  network_link_service { id = confluent_network_link_service.west[0].id }
  depends_on = [confluent_kafka_cluster.east, confluent_kafka_cluster.west]
}
