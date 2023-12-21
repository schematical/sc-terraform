# Terraform configuration


terraform {
  backend "s3" {
    bucket = "schematical-terraform-v1"
    region = "us-east-1"
    key    = "schematical/terraform.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.61.0"
    }
  }

  required_version = ">= 1.5.7"
}
provider "aws" {
  profile  = "schematical"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}
locals {
  default_hosted_zone_name = "schematical.com"
  default_hosted_zone_id = "ZC4VPG65C2OOQ"
  acm_cert_arn = "arn:aws:acm:us-east-1:368590945923:certificate/2df7c33d-9569-41ab-94ed-0d2638369c21"
}
resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
     /* "/" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }*/
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
resource "aws_iam_role" "anywhere_iam_role" {
  name = "ECSAnywhereIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

module "vpc" {
  source = "../modules/vpc"
  vpc_name = "dev"
  # bastion_keypair_name = "schematical_node_1"
}
resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "schematical-codebuild-v1"
}

//TODO: Move this to the `projects/shared/env` module
module "dev_env" {
  source = "../modules/apigateway-env"
  env = "dev"
  acm_cert_arn = local.acm_cert_arn
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  hosted_zone_id = local.default_hosted_zone_id
  hosted_zone_name = local.default_hosted_zone_name
  xray_tracing_enabled=true
  //vpc_id = module.vpc.vpc_id
  //private_subnet_mappings = module.vpc.private_subnet_mappings
  //bastion_security_group = module.vpc.bastion_security_group
  //ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role

}
//TODO: Move this to the `projects/shared/env` module
module "prod_env" {
  source = "../modules/apigateway-env"
  env = "prod"
  acm_cert_arn = local.acm_cert_arn
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  hosted_zone_id = local.default_hosted_zone_id
  hosted_zone_name = local.default_hosted_zone_name
  xray_tracing_enabled=true
  //vpc_id = module.vpc.vpc_id
  //private_subnet_mappings = module.vpc.private_subnet_mappings
  //bastion_security_group = module.vpc.bastion_security_group
  //ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role

}


module "shared_env" {
  source = "./projects/shared"
  private_subnet_mappings = module.vpc.private_subnet_mappings
  public_subnet_mappings  = module.vpc.public_subnet_mappings
  vpc_id                  = module.vpc.vpc_id
}



locals {
  env_info = {
    dev: {
      name = "dev"
      vpc_id = module.vpc.vpc_id
      private_subnet_mappings = module.vpc.private_subnet_mappings
      public_subnet_mappings = module.vpc.public_subnet_mappings
      codepipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket
      api_gateway_stage_id = module.dev_env.api_gateway_stage_id
      bastion_security_group = module.vpc.bastion_security_group
      secrets: var.dev_secrets
      hosted_zone_id = local.default_hosted_zone_id
      hosted_zone_name = local.default_hosted_zone_name
      acm_cert_arn = local.acm_cert_arn

    },
    prod: {
      name = "prod"
      vpc_id = module.vpc.vpc_id
      private_subnet_mappings = module.vpc.private_subnet_mappings
      public_subnet_mappings = module.vpc.public_subnet_mappings
      codepipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket
      api_gateway_stage_id = module.prod_env.api_gateway_stage_id
      bastion_security_group = module.vpc.bastion_security_group
      secrets: var.prod_secrets
      hosted_zone_id = local.default_hosted_zone_id
      hosted_zone_name = local.default_hosted_zone_name
      acm_cert_arn = local.acm_cert_arn
     /* shared_alb = module.shared_env.prod_shared_env.shared_alb
      shared_alb_http_listener_arn = module.shared_env.prod_shared_env.shared_alb_http_listener_arn
      shared_alb_https_listener_arn = module.shared_env.prod_shared_env.shared_alb_https_listener_arn*/
      ecs_cluster = module.shared_env.prod_shared_env.ecs_cluster
      shared_acm_cert_arn = module.shared_env.shared_acm_cert.arn

    }
  }
}


module "project_chaospixel" {
  source = "./projects/chaospixel"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  api_gateway_base_path_mapping = aws_api_gateway_integration.api_gateway_root_resource_method_integration.resource_id
  hosted_zone_id = local.default_hosted_zone_id
  hosted_zone_name = local.default_hosted_zone_name
  env_info = local.env_info
}
module "project_drawnby_ai" {
  source = "./projects/drawnby_ai"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  // api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  env_info = local.env_info
}

module "project_schematical_com" {
  source = "./projects/schematical_com"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  // api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  env_info = local.env_info
}

/*module "project_shiporgetoffthepot_com" {
  source = "./projects/shiporgetoffthepot_com"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  env_info = local.env_info
}*/


