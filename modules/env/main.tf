
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  depends_on = [aws_api_gateway_stage.api_gateway_stage]
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
  rest_api_id = var.api_gateway_id
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
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.id
    evaluate_target_health = false
  }
  zone_id = var.hosted_zone_id
}

data "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone_name
}

resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "codebuild-bucket-${var.env}-${var.region}"
}

resource "aws_api_gateway_base_path_mapping" "APIGatewayBasePathMapping" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.env
  domain_name = aws_api_gateway_domain_name.APIGatewayDomainName.id
}

resource "aws_api_gateway_domain_name" "APIGatewayDomainName" {
  domain_name = join("", [var.env, "-v1-", var.region, "-api.", var.hosted_zone_name])
  certificate_arn = var.acm_cert_arn
  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_route53_record" "Route53" {
  name = join("", [var.env, "-v1-", var.region, "-api.", var.hosted_zone_name, "."])
  type = "A"
  set_identifier = var.env
  alias {
    name                   = aws_api_gateway_domain_name.APIGatewayDomainName.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.APIGatewayDomainName.regional_zone_id
    evaluate_target_health = false
  }
  zone_id = data.aws_route53_zone.hosted_zone.id
}

