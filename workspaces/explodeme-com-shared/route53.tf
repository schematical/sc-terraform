#terraform import module.project_explodeme_com.aws_route53_zone.explodeme_com Z00408211L2QQHQLJ5SKA
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}


resource "aws_route53_zone" "explodeme_com" {
  name = local.domain_name
}
resource "aws_route53domains_registered_domain" "explodeme_com_registered_domain" {
  domain_name = local.domain_name

  dynamic  "name_server" {
    for_each = aws_route53_zone.explodeme_com.name_servers
    content {
      name = name_server.value
    }
  }

}
