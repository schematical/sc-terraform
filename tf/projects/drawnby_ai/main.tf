resource "aws_acm_certificate" "drawnby_ai_cert" {
  domain_name       = aws_route53_zone.drawnby_ai.name
  subject_alternative_names = ["*.${aws_route53_zone.drawnby_ai.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_zone" "drawnby_ai" {
  name = "drawnby.ai"
}
/*resource "aws_route53_record" "drawnby-ai-ns" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.drawnby_ai.name_servers
}*/
resource "aws_route53_record" "drawnby-ai-a" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "A"
  ttl     = "30"
  records = [
    "148.105.251.18"
  ]
}
resource "aws_route53_record" "drawnby-ai-mx" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "MX"
  ttl     = "30"
  records = [
    "1 smtp.google.com",
    "15 x3l2qeaeoiryilvskwynklcu7wsxyy7gdmad3c4ygchmtrgzx4qa.mx-verification.google.com"
  ]
}
/*resource "aws_route53_record" "drawnby-ai-soa" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = ""
  type    = "SOA"
  ttl     = "30"
  records = [
    aws_route53_zone.drawnby_ai.primary_name_server
  ]
}*/
resource "aws_route53_record" "drawnby-ai-cname-www" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "us21-93119a0c-eca5fb707a2d3f78196c48655.pages.mailchi.mp"
  ]
}
resource "aws_route53_record" "drawnby-ai-cname-mc-1" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "k2._domainkey"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "dkim2.mcsv.net"
  ]
}
resource "aws_route53_record" "drawnby-ai-cname-mc-2" {
  zone_id = aws_route53_zone.drawnby_ai.zone_id
  name    = "k3._domainkey"
  type    = "CNAME"
  ttl     = "30"
  records = [
    "dkim3.mcsv.net"
  ]
}
module "dev_env_drawnby_ai" {

  source = "./env"
  env = "dev"
  vpc_id = var.vpc_id
  hosted_zone_id = aws_route53_zone.drawnby_ai.id
  hosted_zone_name = aws_route53_zone.drawnby_ai.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  private_subnet_mappings = var.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.drawnby_ai_cert.arn
  # bastion_security_group = var.bastion_security_group

}