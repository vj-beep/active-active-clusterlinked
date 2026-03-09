resource "confluent_api_key" "svc_link_east" {
  count                  = local.supports_cluster_linking ? 1 : 0
  display_name           = "vj-aa-svc-link-east-key"
  description            = "Kafka API Key for svc_link on East cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.svc_link[0].id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.east.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_east]
}

resource "confluent_api_key" "svc_link_west" {
  count                  = local.supports_cluster_linking ? 1 : 0
  display_name           = "vj-aa-svc-link-west-key"
  description            = "Kafka API Key for svc_link on West cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.svc_link[0].id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.west.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_west]
}

resource "confluent_api_key" "manager_east" {
  display_name           = "vj-aa-app-manager-east-key"
  description            = "Kafka API Key for app_manager on East cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_manager.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.east.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_east]
}

resource "confluent_api_key" "manager_west" {
  display_name           = "vj-aa-app-manager-west-key"
  description            = "Kafka API Key for app_manager on West cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_manager.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.west.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_west]
}

resource "confluent_api_key" "producer_east" {
  display_name           = "vj-aa-app-producer-east-key"
  description            = "Kafka API Key for app_producer on East cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_producer.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.east.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_east]
}

resource "confluent_api_key" "producer_west" {
  display_name           = "vj-aa-app-producer-west-key"
  description            = "Kafka API Key for app_producer on West cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_producer.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.west.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_west]
}

resource "confluent_api_key" "consumer_east" {
  display_name           = "vj-aa-app-consumer-east-key"
  description            = "Kafka API Key for app_consumer on East cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_consumer.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.east.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_east]
}

resource "confluent_api_key" "consumer_west" {
  display_name           = "vj-aa-app-consumer-west-key"
  description            = "Kafka API Key for app_consumer on West cluster"
  disable_wait_for_ready = local.is_private

  owner {
    id          = confluent_service_account.app_consumer.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = confluent_kafka_cluster.west.id
    api_version = "cmk/v2"
    kind        = "Cluster"
    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [time_sleep.rbac_propagation, module.privatelink_west]
}
