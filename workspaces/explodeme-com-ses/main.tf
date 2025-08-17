terraform {
  backend "s3" {
    bucket = "schematical2-terraform-v1"
    region = "us-east-1"
    key    = "sc-workspaces-explodeme-com-ses/terraform.tfstate"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}
module "ses" {
  source = "../../modules/bluefox-email"
  domains = ["splittestgpt.com"]
}