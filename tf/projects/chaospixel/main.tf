data "aws_caller_identity" "current" {}
resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = var.api_gateway_id # aws_api_gateway_rest_api.MyDemoAPI.id
  parent_id   = var.api_gateway_base_path_mapping # aws_api_gateway_rest_api.MyDemoAPI.root_resource_id
  path_part   = "chaospixel"
}
resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "ANY"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_gateway_root_resource_method_integration" {
  rest_api_id          = var.api_gateway_id
  resource_id          = aws_api_gateway_resource.api_gateway_resource.id
  http_method          = aws_api_gateway_method.api_gateway_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  // passthrough_behavior    = "WHEN_NO_MATCH"
  // content_handling        = "CONVERT_TO_BINARY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:sc-chaospixel-v1-$${stageVariables.ENV}-gql/invocations"
}

module "dev_env_chaospixel" {

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

module "prod_env_chaospixel" {

  source = "./env"
  env = "prod"
  secrets = var.env_info.prod.secrets
  vpc_id = var.env_info.prod.vpc_id
  hosted_zone_id = var.env_info.prod.hosted_zone_id
  hosted_zone_name = var.env_info.prod.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role

  private_subnet_mappings = var.env_info.prod.private_subnet_mappings
  codepipeline_artifact_store_bucket = var.env_info.prod.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_id = var.api_gateway_id
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  api_gateway_stage_id          = var.env_info.prod.api_gateway_stage_id
  bastion_security_group        = var.env_info.prod.bastion_security_group
  acm_cert_arn = var.env_info.prod.acm_cert_arn
  kinesis_stream_arn = var.env_info.dev.kinesis_stream_arn
}
