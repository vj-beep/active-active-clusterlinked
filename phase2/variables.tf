variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "environment_id" {
  type = string
}

variable "east_cluster_id" {
  type = string
}

variable "east_rest_endpoint" {
  type = string
}

variable "east_bootstrap_endpoint" {
  type = string
}

variable "west_cluster_id" {
  type = string
}

variable "west_rest_endpoint" {
  type = string
}

variable "west_bootstrap_endpoint" {
  type = string
}

variable "manager_east_key" {
  type = string
}

variable "manager_east_secret" {
  type      = string
  sensitive = true
}

variable "manager_west_key" {
  type = string
}

variable "manager_west_secret" {
  type      = string
  sensitive = true
}

variable "svc_link_east_key" {
  type    = string
  default = ""
}

variable "svc_link_east_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "svc_link_west_key" {
  type    = string
  default = ""
}

variable "svc_link_west_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "topic_name_east" {
  type    = string
  default = "orders_east"
}

variable "topic_name_west" {
  type    = string
  default = "orders_west"
}

variable "topic_partitions" {
  type    = number
  default = 3
}

variable "supports_cluster_linking" {
  type    = bool
  default = true
}
