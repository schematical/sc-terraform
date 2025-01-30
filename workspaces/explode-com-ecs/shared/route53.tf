#terraform import module.project_explodeme_com.aws_route53_zone.explodeme_com Z00408211L2QQHQLJ5SKA
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}
locals {
  domain_name = "splitgpt.com"
}

resource "aws_route53_zone" "explodeme_com" {
  name = local.domain_name
}
resource "aws_route53_record" "route53_record_a1" {
  zone_id = aws_route53_zone.explodeme_com.zone_id
  name    = local.domain_name
  type    = "A"
  ttl     = 300
  records = [
    "3.13.222.255",
    "3.13.246.91",
    "3.130.60.26"
  ]
}
