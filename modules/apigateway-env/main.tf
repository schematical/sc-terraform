
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  # depends_on = [aws_api_gateway_stage.api_gateway_stage]
  description = "module apigateway-env deployment"
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  lifecycle {
    ignore_changes = [
      deployment_id
    ]
  }
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  stage_name   = var.env
  rest_api_id  = var.api_gateway_id
  variables    = {
    ENV = var.env
  }
  xray_tracing_enabled=var.xray_tracing_enabled
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size = var.cache_cluster_size
}
resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.id
  api_id = var.api_gateway_id
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name
}


resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = var.acm_cert_arn
  domain_name     = var.domain_name != "" ? "${var.domain_name}.${var.hosted_zone_name}" : "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}"
  endpoint_configuration {
    types = ["EDGE"]
  }
}


resource "aws_route53_record" "route53_record" {
  name = aws_api_gateway_domain_name.api_gateway_domain_name.domain_name # "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}."
  type = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
  zone_id = var.hosted_zone_id
}

data "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone_name
  private_zone = false
}














