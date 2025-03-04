
terraform {
 /* backend "s3" {
    bucket = "cwg-scenerio-tf"
    region = "us-east-1"
    key    = "advanced/2.tfstate"
  }*/
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.88.0"
    }
  }

  required_version = ">= 1.5.7"
}
provider "aws" {
  // profile  = "schematical-2"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}