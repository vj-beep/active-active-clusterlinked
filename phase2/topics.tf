resource "confluent_kafka_topic" "east" {
  kafka_cluster {
    id = var.east_cluster_id
  }

  topic_name       = var.topic_name_east
  rest_endpoint    = var.east_rest_endpoint
  partitions_count = var.topic_partitions

  credentials {
    key    = var.manager_east_key
    secret = var.manager_east_secret
  }
}

resource "confluent_kafka_topic" "west" {
  kafka_cluster {
    id = var.west_cluster_id
  }

  topic_name       = var.topic_name_west
  rest_endpoint    = var.west_rest_endpoint
  partitions_count = var.topic_partitions

  credentials {
    key    = var.manager_west_key
    secret = var.manager_west_secret
  }
}
