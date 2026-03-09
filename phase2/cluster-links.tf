resource "confluent_cluster_link" "east_to_west" {
  count     = var.supports_cluster_linking ? 1 : 0
  link_name = "vj-aa-east-to-west"

  source_kafka_cluster {
    id                 = var.east_cluster_id
    bootstrap_endpoint = var.east_bootstrap_endpoint
    credentials {
      key    = var.svc_link_east_key
      secret = var.svc_link_east_secret
    }
  }

  destination_kafka_cluster {
    id            = var.west_cluster_id
    rest_endpoint = var.west_rest_endpoint
    credentials {
      key    = var.svc_link_west_key
      secret = var.svc_link_west_secret
    }
  }
}

resource "confluent_cluster_link" "west_to_east" {
  count     = var.supports_cluster_linking ? 1 : 0
  link_name = "vj-aa-west-to-east"

  source_kafka_cluster {
    id                 = var.west_cluster_id
    bootstrap_endpoint = var.west_bootstrap_endpoint
    credentials {
      key    = var.svc_link_west_key
      secret = var.svc_link_west_secret
    }
  }

  destination_kafka_cluster {
    id            = var.east_cluster_id
    rest_endpoint = var.east_rest_endpoint
    credentials {
      key    = var.svc_link_east_key
      secret = var.svc_link_east_secret
    }
  }
}

resource "confluent_kafka_mirror_topic" "east_to_west" {
  count = var.supports_cluster_linking ? 1 : 0

  source_kafka_topic {
    topic_name = var.topic_name_east
  }

  cluster_link {
    link_name = confluent_cluster_link.east_to_west[0].link_name
  }

  kafka_cluster {
    id            = var.west_cluster_id
    rest_endpoint = var.
