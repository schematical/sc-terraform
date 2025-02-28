data "aws_caller_identity" "current" {}
locals {
  cloudfront_subdomain = "assets-${var.env}"
}
locals{
  container_port = 3000
  NEXT_PUBLIC_SERVER_URL = "https://${var.subdomain}.${var.hosted_zone_name}"
  PUBLIC_ASSET_URL = "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
}
module "nextjs_lambda" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../../modules/nextjs-lambda-frontend-env"
  env = var.env
  service_name = "${var.service_name}"
  vpc_id = var.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  private_subnet_mappings = var.private_subnet_mappings
  acm_cert_arn = var.acm_cert_arn
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  subdomain = var.subdomain
  secrets = var.secrets
  github_owner = "schematical"
  github_project_name = "cloudwargames-com"
  source_buildspec_path = "www/buildspec.yml"
  cache_cluster_enabled = false
  cache_cluster_size = "0.5"
  extra_env_vars = {
    REDIS_HOST: var.redis_host
    # DEBUG: "ioredis:*"
    ENV: var.env
    TEMPLATE_API_KEY: var.secrets.schematical_lambda_service_TEMPLATE_API_KEY
    CALENDLY_API_KEY: var.secrets.schematical_lambda_service_CALENDLY_API_KEY
    CONVERTKIT_API_SECRET: var.secrets.schematical_lambda_service_CONVERTKIT_API_SECRET
    POSTHOG_API_KEY: var.secrets.schematical_lambda_service_POSTHOG_API_KEY
    MAKE_COM_WEBHOOK: var.secrets.schematical_lambda_service_MAKE_COM_WEBHOOK

  }
  xray_tracing_enabled = true
  codestar_connection_arn = var.codestar_connection_arn
}
/*
resource "aws_api_gateway_method_settings" "root" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.env # module.nextjs_lambda.api_gateway_stage_id
  method_path = "GET"
  settings {
    caching_enabled = false
  }
}
resource "aws_api_gateway_method_settings" "posts" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.env # module.nextjs_lambda.api_gateway_stage_id
  method_path = "/posts"

  settings {
    caching_enabled = false
  }
}
*/


resource "aws_iam_policy" "lambda_iam_policy" {
  name = "cloudwargames-com-v1-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "DynamoDB",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:BatchGetItem",
            "dynamodb:DeleteItem"
          ],
          "Resource" : var.dynamodb_table_arns
        }

      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role = module.nextjs_lambda.iam_role_name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
resource "aws_wafv2_web_acl_association" "wafv2_web_acl_association" {
  resource_arn = module.nextjs_lambda.api_gateway_stage_arn
  web_acl_arn  = var.waf_web_acl_arn
}