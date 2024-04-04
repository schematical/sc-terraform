data "aws_caller_identity" "current" {}
locals {
  service_name = "splitgpt-com"
  domain_name = "splittestgpt.com"
}
provider "aws" {
  region = "us-east-1"
  # alias  = "east"
}
resource "aws_route53_zone" "domain_name_com" {
  name = local.domain_name
}

module "nextjs_lambda_frontend_base" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../modules/nextjs-lambda-frontent-base"


  base_domain_name = local.domain_name
  service_name     = local.service_name
  api_gateway_stage_name = "dev"
  aws_route53_zone_id = aws_route53_zone.domain_name_com.zone_id
}



module "dev_env_indihustlers_com" {
  depends_on = [module.nextjs_lambda_frontend_base]
  service_name=local.service_name
  source = "./env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.domain_name_com.zone_id
  hosted_zone_name = aws_route53_zone.domain_name_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = module.nextjs_lambda_frontend_base.aws_apigateway_rest_api_id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = module.nextjs_lambda_frontend_base.aws_acm_certificate_arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  api_gateway_base_path_mapping = module.nextjs_lambda_frontend_base.aws_api_gateway_rest_api_root_resource_id
  subdomain = "dev"

  secrets = var.env_info.dev.secrets

}

module "prod_env_indihustlers_com" {
  depends_on = [module.nextjs_lambda_frontend_base]
  source = "./env"
  env = "prod"
  service_name=local.service_name
  vpc_id = var.env_info.prod.vpc_id
  hosted_zone_id = aws_route53_zone.domain_name_com.zone_id
  hosted_zone_name = aws_route53_zone.domain_name_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = module.nextjs_lambda_frontend_base.aws_apigateway_rest_api_id
  private_subnet_mappings = var.env_info.prod.private_subnet_mappings
  acm_cert_arn = module.nextjs_lambda_frontend_base.aws_acm_certificate_arn
  codepipeline_artifact_store_bucket = var.env_info.prod.codepipeline_artifact_store_bucket
  api_gateway_base_path_mapping = module.nextjs_lambda_frontend_base.aws_api_gateway_rest_api_root_resource_id
  subdomain = "www"

  secrets = var.env_info.prod.secrets
}