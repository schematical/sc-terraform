data "aws_caller_identity" "current" {}
locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:sc-drawnby-www-v1-$${stageVariables.ENV}-www/invocations"
}
resource "aws_acm_certificate" "drawnby_ai_cert" {
  domain_name       = aws_route53_zone.drawnby_ai.name
  subject_alternative_names = ["*.${aws_route53_zone.drawnby_ai.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "drawnby_ai" {
  name = "drawnby.ai"
}
/*resource "aws_route53_record" "drawnby-ai-ns" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.drawnby_ai.name_servers
}*/
resource "aws_route53_record" "drawnby-ai-a" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "A"
  ttl     = "30"
  records = [
    "148.105.251.18"
  ]
}
resource "aws_route53_record" "drawnby-ai-mx" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "MX"
  ttl     = "30"
  records = [
    "1 smtp.google.com",
    "15 x3l2qeaeoiryilvskwynklcu7wsxyy7gdmad3c4ygchmtrgzx4qa.mx-verification.google.com"
  ]
}
/*resource "aws_route53_record" "drawnby-ai-soa" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "SOA"
  ttl     = "30"
  records = [
    aws_route53_zone.drawnby_ai.primary_name_server
  ]
}*/
resource "aws_route53_record" "drawnby-ai-cname-www" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "us21-93119a0c-eca5fb707a2d3f78196c48655.pages.mailchi.mp"
  ]
}
resource "aws_route53_record" "drawnby-ai-cname-mc-1" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "k2._domainkey"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "dkim2.mcsv.net"
  ]
}
resource "aws_route53_record" "drawnby-ai-cname-mc-2" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "k3._domainkey"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "dkim3.mcsv.net"
  ]
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

  name = "drawnby-www-v1"

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


module "dev_env_drawnby_ai" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.drawnby_ai.id
  hosted_zone_name = aws_route53_zone.drawnby_ai.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.drawnby_ai_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
}