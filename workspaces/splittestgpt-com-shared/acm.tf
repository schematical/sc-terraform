
resource "aws_acm_certificate" "cloudwargames_com_cert" {
  domain_name       = aws_route53_zone.explodeme_com.name
  subject_alternative_names = ["*.${aws_route53_zone.explodeme_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws_acm_certificate_route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.cloudwargames_com_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.explodeme_com.zone_id
}