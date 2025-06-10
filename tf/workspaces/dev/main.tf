module "dev_shared_env" {
  source = "../../modules/shared_env"
  env = "dev"
  vpc_id = var.vpc_id
  public_subnet_mappings = var.public_subnet_mappings
  private_subnet_mappings = var.private_subnet_mappings
  shared_acm_cert_arn = aws_acm_certificate.shared_acm_cert.arn
}
module "dev_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../modules/schematical_env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.schematical_com.id
  hosted_zone_name = aws_route53_zone.schematical_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.schematical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  secrets = var.env_info.dev.secrets
  dynamodb_table_arns = [
    aws_dynamodb_table.dynamodb_table_post.arn,

  ]
  service_name = local.service_name
  subdomain = "dev"
  redis_host =  join(",", [for o in aws_elasticache_cluster.elasticache_cluster.cache_nodes : o.address]) # join(",", [for o in aws_elasticache_serverless_cache.elasticache_serverless_cache.endpoint : o.address])
  waf_web_acl_arn = var.env_info.prod.waf_web_acl_arn
  alb_arn = var.env_info.dev.shared_alb.alb_arn
  alb_dns_name = var.env_info.dev.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.dev.shared_alb.alb_hosted_zone_id
  ecs_cluster_id = var.env_info.dev.ecs_cluster.id
  ecs_cluster_name = "prod-v1"
  lb_http_listener_arn = var.env_info.dev.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.dev.shared_alb_https_listener_arn
  shared_alb_sg_id = var.env_info.dev.shared_alb.alb_sg_id
  codestar_connection_arn = var.env_info.dev.codestar_connection_arn
}