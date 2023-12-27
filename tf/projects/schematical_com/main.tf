data "aws_caller_identity" "current" {}
locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:schematical-com-v1-$${stageVariables.ENV}-www/invocations"
}
provider "aws" {
  region = "us-east-1"
  # alias  = "east"
}
resource "aws_acm_certificate" "schematical_com_cert" {
  domain_name       = aws_route53_zone.schematical_com.name
  subject_alternative_names = ["*.${aws_route53_zone.schematical_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "schematical_com" {
  name = "schematical.com"
}
/*resource "aws_route53_record" "schematical-com-ns" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.schematical_com.name_servers
}*/
resource "aws_route53_record" "schematical-com-a" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "schematical.com"
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.id
  api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = module.prod_env_schematical_com.apigateway_env.api_gateway_stage_name
}


resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = aws_acm_certificate.schematical_com_cert.arn
  domain_name     = "schematical.com"
  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_route53_record" "schematical-com-mx" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "schematical.com"
  type    = "MX"
  ttl     = "30"
  records = [
    "10 ASPMX.L.GOOGLE.COM.",
    "20 ALT1.ASPMX.L.GOOGLE.COM.",
    "30 ALT2.ASPMX.L.GOOGLE.COM.",
    "40 ASPMX2.GOOGLEMAIL.COM.",
    "50 ASPMX3.GOOGLEMAIL.COM."
  ]
}
resource "aws_ses_domain_identity" "ses_domain_identity" {
  domain = "schematical.com"
}


resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {

    }
  })

  name = "schematical-com-v1"

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

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_BINARY"
  uri = local.www_lambda_arn
}

resource "aws_api_gateway_resource" "api_gateway_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "api_gateway_proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_gateway_proxy_resource_method_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.api_gateway_proxy_resource.id
  http_method          = aws_api_gateway_method.api_gateway_proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_BINARY"
  uri = local.www_lambda_arn
}

resource "aws_dynamodb_table" "dynamodb_table_post" {
  name           = "SchematicalComPost"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PostId"
  range_key      = "PublicDate"

  attribute {
    name = "PostId"
    type = "S"
  }

/*  attribute {
    name = "Title"
    type = "S"
  }

  attribute {
    name = "Body"
    type = "S"
  }*/
  attribute {
    name = "PublicDate"
    type = "S"
  }
/*
  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }*/

 /* global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }*/

  tags = {
    Name        = "schematical-com"
  }
}

module "dev_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.schematical_com.id
  hosted_zone_name = aws_route53_zone.schematical_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.schematical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  domain_name = "dev"

  secrets = var.env_info.dev.secrets
  dynamodb_table_post_arn = aws_dynamodb_table.dynamodb_table_post.arn
}

module "prod_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.schematical_com.id
  hosted_zone_name = aws_route53_zone.schematical_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.schematical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  domain_name = "www"

  secrets = var.env_info.prod.secrets
  dynamodb_table_post_arn = aws_dynamodb_table.dynamodb_table_post.arn
}