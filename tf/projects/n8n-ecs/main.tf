data "aws_caller_identity" "current" {}
locals {
  service_name = "n8n"
  domain_name = "schematical.com"
  env = "prod"
}
data "aws_route53_zone" "schematical_com"{
  name = local.domain_name
}
data "aws_route53_zone" "domain_name_com"{
  name = local.domain_name
}
module "prod_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = data.aws_route53_zone.domain_name_com.id
  hosted_zone_name = data.aws_route53_zone.domain_name_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.n8n_scheamtical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  service_name = local.service_name
  subdomain = "n8n"
  secrets = var.env_info.prod.secrets


  waf_web_acl_arn = var.env_info.prod.waf_web_acl_arn

  alb_arn = var.env_info.prod.shared_alb.alb_arn
  alb_dns_name = var.env_info.prod.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.prod.shared_alb.alb_hosted_zone_id
  ecs_cluster_id = var.env_info.prod.ecs_cluster.id
  ecs_cluster_name = "prod-v1"
  lb_http_listener_arn = var.env_info.prod.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.prod.shared_alb_https_listener_arn
  shared_alb_sg_id = var.env_info.prod.shared_alb.alb_sg_id
  codestar_connection_arn = var.env_info.prod.codestar_connection_arn
  dsql_cluster_identifier = aws_dsql_cluster.dsql_cluster.identifier
}