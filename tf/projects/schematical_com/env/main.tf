data "aws_caller_identity" "current" {}
/*module "nextjs_lambda" {
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
  github_project_name = "schematical-com"
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

  }
  xray_tracing_enabled = true

}*/
/*
resource "aws_api_gateway_method_settings" "root" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.env # module.nextjs_lambda.api_gateway_stage_id
  method_path = "GET"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 60
  }
}
resource "aws_api_gateway_method_settings" "posts" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.env # module.nextjs_lambda.api_gateway_stage_id
  method_path = "/posts"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 60
  }
}
*/


resource "aws_iam_policy" "lambda_iam_policy" {
  name = "schematical-com-v1-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "DynamoDB",
          "Effect": "Allow",
          "Action": [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:BatchGetItem"
          ],
          "Resource": var.dynamodb_table_arns
        }

      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role = module.env_schematical_com_ecs_service.ecs_task_execution_iam_role_name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
/*resource "aws_wafv2_web_acl_association" "wafv2_web_acl_association" {
  resource_arn = module.env_schematical_com_ecs_service.api_gateway_stage_arn
  web_acl_arn  = var.waf_web_acl_arn
}*/



resource "aws_ecr_repository" "ecr_repo" {
  name                 = "schematical-com-${var.env}-${var.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "env_schematical_com_tg" {
  source = "../../../../modules/alb-ecs-service-association"
  env = var.env
  service_name = "schematical-com"
  vpc_id = var.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  subdomain = var.subdomain
  alb_arn = var.alb_arn
  alb_dns_name = var.alb_dns_name
  alb_hosted_zone_id = var.alb_hosted_zone_id
  container_port = 80
  alb_target_group_health_check_path = "/"
  lb_http_listener_arn =  var.lb_http_listener_arn
  lb_https_listener_arn = var.lb_https_listener_arn
  lb_listener_rule_http_rule_priority = var.env == "prod" ? 1 : 2
}
module "env_schematical_com_ecs_service" {
  source = "../../../../modules/ecs-service"
  env = var.env
  vpc_id = var.vpc_id
  service_name = "schematical-com-v1"
  ecs_desired_task_count = 1
  private_subnet_mappings = var.private_subnet_mappings
  // aws_lb_target_group_arns = [module.env_schematical_com_tg.aws_lb_target_group_arn]
  ecs_cluster_id = var.ecs_cluster_id
  ingress_security_groups = [
    var.shared_alb_sg_id
  ]
  ecr_image_uri = "${aws_ecr_repository.ecr_repo.repository_url}:${var.env}"
  container_port = 80
  create_secrets = false
  task_definition_environment_vars = [
    {
      name: "NODE_ENV ",
      value: var.env
    },
    {
      name: "REDIS_HOST",
      value: var.redis_host
    },
    {
      name: "ENV",
      value: var.env
    },
    {
      name: "TEMPLATE_API_KEY",
      value: var.secrets.schematical_lambda_service_TEMPLATE_API_KEY
    },
    {
      name: "CALENDLY_API_KEY",
      value: var.secrets.schematical_lambda_service_CALENDLY_API_KEY
    },
    {
      name: "CONVERTKIT_API_SECRET",
      value: var.secrets.schematical_lambda_service_CONVERTKIT_API_SECRET
    },
    {
      name: "POSTHOG_API_KEY",
      value: var.secrets.schematical_lambda_service_POSTHOG_API_KEY
    }
  ]
}
module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "schematical-com-v1"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "schematical-com"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "www/buildspec.yml"
  ecs_deploy_cluster = var.ecs_cluster_id
  ecs_deploy_service_name = var.service_name
  env_vars = {
    REDIS_HOST: var.redis_host
    # DEBUG: "ioredis:*"
    ENV: var.env
    TEMPLATE_API_KEY: var.secrets.schematical_lambda_service_TEMPLATE_API_KEY
    CALENDLY_API_KEY: var.secrets.schematical_lambda_service_CALENDLY_API_KEY
    CONVERTKIT_API_SECRET: var.secrets.schematical_lambda_service_CONVERTKIT_API_SECRET
    POSTHOG_API_KEY: var.secrets.schematical_lambda_service_POSTHOG_API_KEY
  }

}
