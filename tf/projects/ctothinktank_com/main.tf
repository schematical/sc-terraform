data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

resource "aws_route53_zone" "ctothinktank_com" {
  name = "ctothinktank.com"
}
resource "aws_route53_record" "route53_record_a1" {
  zone_id = aws_route53_zone.ctothinktank_com.zone_id
  name    = "ctothinktank.com"
  type    = "A"
  ttl     = 300
  records = [
    "3.13.222.255",
    "3.13.246.91",
    "3.130.60.26"
  ]
}
#terraform import module.project_ctothinktank_com.aws_route53_zone.ctothinktank_com Z00408211L2QQHQLJ5SKA