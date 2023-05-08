# Terraform configuration

provider "aws" {
  profile  = "schematical"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}
terraform {
  backend "s3" {
    bucket = "schematical-terraform-v1"
    region = "us-east-1"
    key    = "schematical/terraform.tfstate"
  }
}
locals {
  default_hosted_zone_name = "schematical.com"
  default_hosted_zone_id = "ZC4VPG65C2OOQ"
}
resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name = "schematical-terraform-v1"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_gateway_root_resource_method_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method          = aws_api_gateway_method.api_gateway_method.http_method
  type                 = "MOCK"
  # cache_key_parameters = ["method.request.path.param"]
  # cache_namespace      = "foobar"
  timeout_milliseconds = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}

resource "aws_s3_bucket" "code_pipeline_artifact_store_bucket" {
  # Add your bucket configuration here
}

resource "aws_iam_role" "ecs_task_execution_iam_role" {
  name = "ECSTaskExecutionIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}
module "vpc" {
  source = "../modules/vpc"
  vpc_name = "dev"
  bastion_keypair_name = "schematical_node_1"
}
module "dev_env" {
/*  depends_on = [
    aws_api_gateway_method.api_gateway_method,
    aws_api_gateway_integration.api_gateway_root_resource_method_integration
  ]*/
  source = "../modules/env"
  env = "dev"
  vpc_id = module.vpc.vpc_id
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  hosted_zone_id = local.default_hosted_zone_id
  hosted_zone_name = local.default_hosted_zone_name
  private_subnet_mappings = module.vpc.private_subnet_mappings
  bastion_security_group = module.vpc.bastion_security_group

}
locals {
  env_info = {
    dev: {
      name = "dev"
      vpc_id = module.vpc.vpc_id
      private_subnet_mappings = module.vpc.private_subnet_mappings
      codepipeline_artifact_store_bucket = module.dev_env.codepipeline_artifact_store_bucket
      api_gateway_stage_id = module.dev_env.api_gateway_stage_id
      bastion_security_group = module.vpc.bastion_security_group
    }
  }
}
module "project_chaospixel" {
  source = "./projects/chaospixel"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  api_gateway_base_path_mapping = aws_api_gateway_integration.api_gateway_root_resource_method_integration.id
  hosted_zone_id = local.default_hosted_zone_id
  hosted_zone_name = local.default_hosted_zone_name
  env_info = local.env_info
}
module "project_drawnby_ai" {
  source = "./projects/drawnby_ai"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  env_info = local.env_info
}


