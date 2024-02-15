data "aws_caller_identity" "current" {}
/*locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:schematical-com-v1-$${stageVariables.ENV}-www/invocations"
}*/
provider "aws" {
  region = "us-east-1"
  # alias  = "east"
}
module "dev_env_chaoscrawler" {

  source = "./env"
  env = "dev"
  secrets = var.env_info.dev.secrets
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = var.env_info.dev.hosted_zone_id
  hosted_zone_name = var.env_info.dev.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role

  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_id = var.api_gateway_id
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  api_gateway_stage_id          = var.env_info.dev.api_gateway_stage_id
  bastion_security_group        = var.env_info.dev.bastion_security_group
  acm_cert_arn = var.env_info.dev.acm_cert_arn
  kinesis_stream_arn = var.env_info.dev.kinesis_stream_arn
}