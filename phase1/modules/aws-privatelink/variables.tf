variable "network_dns_domain" {
  type = string
}

variable "private_link_endpoint_service" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "dns_ttl" {
  type    = number
  default = 300
}
