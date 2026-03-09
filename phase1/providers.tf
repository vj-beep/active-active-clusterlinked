terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.62.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

provider "aws" {
  alias  = "east"
  region = var.region_east
}

provider "aws" {
  alias  = "west"
  region = var.region_west
}
