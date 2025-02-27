


/*resource "aws_route53_record" "domain_name_a" {
  zone_id = var.aws_route53_zone_id
  name    = var.base_domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}*/
/*
resource "aws_acm_certificate" "aws_acm_certificate" {
  domain_name       = var.base_domain_name
  subject_alternative_names = ["*.${var.base_domain_name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
*/
