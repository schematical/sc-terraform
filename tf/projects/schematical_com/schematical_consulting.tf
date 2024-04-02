locals {
  sc_domain_name = "schematicalconsulting.com"
}
resource "aws_route53_zone" "schematical_consulting_com" {
  name = local.sc_domain_name
}
/*resource "aws_route53_record" "schematical-com-ns" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.schematical_com.name_servers
}*/
resource "aws_route53_record" "schematical-consulting-a" {
  zone_id = aws_route53_zone.schematical_consulting_com.zone_id
  name    =  local.sc_domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name_sc.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name_sc.cloudfront_zone_id
    evaluate_target_health = false
  }
}
resource "aws_acm_certificate" "schematical_consulting_com_cert" {
  domain_name       = aws_route53_zone.schematical_consulting_com.name
  subject_alternative_names = ["*.${aws_route53_zone.schematical_consulting_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name_sc" {
  certificate_arn = aws_acm_certificate.schematical_consulting_com_cert.arn
  domain_name     = local.sc_domain_name
  endpoint_configuration {
    types = ["EDGE"]
  }
}
resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping_sc" {
  base_path   = "" #"consulting"
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name_sc.id
  api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
}