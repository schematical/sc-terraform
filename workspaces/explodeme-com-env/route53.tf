resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  count = var.env == "prod" ? 1 : 0
  certificate_arn = data.aws_acm_certificate.explodeme_com_acm_certificate.arn
  domain_name     = local.domain_name
  endpoint_configuration {
    types = ["EDGE"]
  }
}
resource "aws_route53_record" "schematical-com-a" {
  count = var.env == "prod" ? 1 : 0
  zone_id = data.aws_route53_zone.explodeme_com_route53_zone.zone_id
  name    =  local.domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name[0].cloudfront_zone_id
    evaluate_target_health = false
  }
}
resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  count = var.env == "prod" ? 1 : 0
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name[0].id
  api_id = data.aws_api_gateway_rest_api.explodme_com_rest_api.id
  stage_name  = var.env
}