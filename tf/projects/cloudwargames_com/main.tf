#terraform import module.project_cloudwargames_com.aws_route53_zone.cloudwargames_com Z00408211L2QQHQLJ5SKA
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}
locals {
  domain_name = "cloudwargames.com"
}

resource "aws_route53_zone" "cloudwargames_com" {
  name = local.domain_name
}
resource "aws_route53_record" "route53_record_a1" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = local.domain_name
  type    = "A"
  ttl     = 300
  records = [
    "3.13.222.255",
    "3.13.246.91",
    "3.130.60.26"
  ]
}






/*


resource "aws_acm_certificate" "cloudwargames_com_cert" {
  domain_name       = aws_route53_zone.cloudwargames_com.name
  subject_alternative_names = ["*.${aws_route53_zone.cloudwargames_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.cloudwargames_com_cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id =  aws_route53_zone.cloudwargames_com.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cloudwargames_com_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}
*/
