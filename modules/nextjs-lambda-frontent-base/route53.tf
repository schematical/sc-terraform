
resource "aws_route53_zone" "domain_name_com" {
  name = var.base_domain_name
}
/*resource "aws_route53_record" "schematical-com-ns" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.schematical_com.name_servers
}*/
resource "aws_route53_record" "domain_name_a" {
  zone_id = aws_route53_zone.domain_name_com.zone_id
  name    = var.base_domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}
resource "aws_acm_certificate" "aws_acm_certificate" {
  domain_name       = aws_route53_zone.domain_name_com.name
  subject_alternative_names = ["*.${aws_route53_zone.domain_name_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
