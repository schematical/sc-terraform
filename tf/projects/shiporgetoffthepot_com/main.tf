data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}
resource "aws_acm_certificate" "shiporgetoffthepot_com_cert" {
  domain_name       = aws_route53_zone.shiporgetoffthepot_com.name
  subject_alternative_names = ["*.${aws_route53_zone.shiporgetoffthepot_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "shiporgetoffthepot_com" {
  name = "shiporgetoffthepot.com"
}
/*resource "aws_route53_record" "schematical-com-a" {
  zone_id = aws_route53_zone.shiporgetoffthepot_com.zone_id
  name    = "schematical.com"
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}*/


module "prod_env_shiporgetoffthepot_com" {
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.shiporgetoffthepot_com.id
  hosted_zone_name = aws_route53_zone.shiporgetoffthepot_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.shiporgetoffthepot_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket

  subdomain = "www"

  secrets = var.env_info.prod.secrets
  env_info = var.env_info.prod
}