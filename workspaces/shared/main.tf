terraform {
  backend "s3" {
    bucket = "schematical2-terraform-v1"
    region = "us-east-1"
    key    = "sc-workspaces-shared/terraform.tfstate"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.85.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}