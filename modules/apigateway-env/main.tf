
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  # depends_on = [aws_api_gateway_stage.api_gateway_stage]
  description = "module apigateway-env deployment"
  stage_description = "module apigateway-env deployment"
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  stage_name   = var.env
  rest_api_id  = var.api_gateway_id
  variables    = {
    ENV = var.env
  }
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.id
  api_id = var.api_gateway_id
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = var.acm_cert_arn
  domain_name     = "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}"
  endpoint_configuration {
    types = ["EDGE"]
  }
}


resource "aws_route53_record" "route53_record" {
  name = "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}."
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
}


/*resource "aws_route53_record" "dev-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.env}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.dev.name_servers
}*/












