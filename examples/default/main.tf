terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.48.0"
    }
  }
}

module "marbot-standalone-topic" {
  source = "../../"

  endpoint_id = var.endpoint_id
}