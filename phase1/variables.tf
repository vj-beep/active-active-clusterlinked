variable "region_east" {
  type    = string
  default = "us-east-1"
}

variable "region_west" {
  type    = string
  default = "us-west-2"
}

variable "vpc_name_east" {
  type = string
}

variable "vpc_name_west" {
  type = string
}

variable "vpc_tag" {
  type = string
}

variable "cloud9_name" {
  type = string
}

variable "cloud9_owner_arn" {
  type = string
}

variable "cloud9_disk_size" {
  type    = number
  default = null
}

variable "cloud9_instance_type" {
  type    = string
  default = "t3.small"
}

variable "cloud9_disable_managed_creds" {
  description = "Set to false to skip disabling Cloud9 managed credentials via Terraform"
  type        = bool
  default     = false
}

variable "west_private_hosted_zone_ids" {
  type    = list(string)
  default = []
}

variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "aws_account_id" {
  type = string
  validation {
    condition     = can(regex("^\\d{12}$", var.aws_account_id))
    error_message = "Must be exactly 12 digits."
  }
}

variable "cluster_type" {
  type    = string
  default = "DEDICATED"
  validation {
    condition     = contains(["BASIC", "STANDARD", "DEDICATED", "ENTERPRISE"], var.cluster_type)
    error_message = "Must be BASIC, STANDARD, DEDICATED, or ENTERPRISE."
  }
}

variable "cluster_name_east" {
  type    = string
  default = "core-app-east"
}

variable "cluster_name_west" {
  type    = string
  default = "core-app-west"
}

variable "environment_name" {
  type    = string
  default = "vj-aa-linkedpl"
}

variable "cluster_availability" {
  type    = string
  default = "SINGLE_ZONE"
}

variable "cluster_cku" {
  type    = number
  default = 1
}

variable "topic_partitions" {
  type    = number
  default = 3
}

variable "topic_name_east" {
  type    = string
  default = "orders_east"
}

variable "topic_name_west" {
  type    = string
  default = "orders_west"
}

variable "consumer_group_prefix" {
  type    = string
  default = "orders-consumer"
}

variable "dns_ttl" {
  type    = number
  default = 300
}

variable "zones_east" {
  type    = list(string)
  default = ["use1-az2", "use1-az4", "use1-az6"]
}

variable "zones_west" {
  type    = list(string)
  default = ["usw2-az1", "usw2-az2", "usw2-az3"]
}
