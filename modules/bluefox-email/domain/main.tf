data "aws_route53_zone" "route53_zone" {
  name         = var.domain
}
resource "aws_ses_domain_identity" "ses_domain_identity" {
  domain = var.domain
}

resource "aws_ses_domain_mail_from" "ses_domain_mail_from" {
  domain           = aws_ses_domain_identity.ses_domain_identity.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.ses_domain_identity.domain}"
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.ses_domain_identity.verification_token]
}
# Example Route53 MX record
resource "aws_route53_record" "example_ses_domain_mail_from_mx" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = aws_ses_domain_mail_from.ses_domain_mail_from.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"] # Change to the region in which `aws_ses_domain_identity.example` is created
}

# Example Route53 TXT record for SPF
resource "aws_route53_record" "example_ses_domain_mail_from_txt" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = aws_ses_domain_mail_from.ses_domain_mail_from.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}