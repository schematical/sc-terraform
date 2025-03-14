

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
