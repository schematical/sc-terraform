# Terraform configuration

provider "aws" {
  profile  = "schematical"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}
resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
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

  name = "example"

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



module "vpc" {
  source = "../../sc-terraform/modules/vpc"
  vpc_name = "dev"
}
/*module "lambda-service" {
  for_each = toset(var.envs)
  source = "../../sc-terraform/modules/lambda-service"
  service_name = "ocr"
  service_env  = each.value
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  api_gateway_parent_id = aws_api_gateway_rest_api.api_gateway.root_resource_id
  api_gateway_stage_id = lookup(var.api_gateway_stages, each.value, "fail")
}*/

