
resource "aws_acm_certificate" "shared_acm_cert" {
  domain_name       = "schematical.com"
  subject_alternative_names = ["*.schematical.com"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_codestarconnections_connection" "codestarconnections_connection" {
  name          = "github-connection"
  provider_type = "GitHub"
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
module "schematical_com" {
  source = "./schematical_com"
  ecs_task_execution_iam_role = aws_iam_role.ecs_task_execution_iam_role
  env_info = {}
}


