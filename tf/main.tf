# Terraform configuration

provider "aws" {
  profile  = "xxxx"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}
module "vpc" {
  source = "../../sc-terraform/modules/vpc"
}
module "lambda-service" {
  for_each = toset(var.envs)
  source = "../../sc-terraform/modules/lambda-service"
  service_name = "ocr"
  service_env  = each.value
  api_gateway_id = var.api_gateway_id
  api_gateway_parent_id = var.api_gateway_parent_id
  api_gateway_stage_id = lookup(var.api_gateway_stages, each.value, "fail")
}
/*resource "aws_api_gateway_stage" "aws_api_gateway_stage" {
  deployment_id = var.api_gateway_stage_id
  rest_api_id   = var.api_gateway_id
  stage_name    = var.service_env
  variables = merge(
  {
    "${join("_", [upper(var.service_prefix),  upper(var.service_name)])}": join("-", [var.service_prefix, var.service_name, var.service_version, var.service_env])
  },
  aws_api_gateway_stage.aws_api_gateway_stage.variables
  )
}*/
