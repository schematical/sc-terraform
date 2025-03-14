data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}
locals {
  domain_name = "splittestgpt.com"
  service_name = "splittestgpt-com"
}