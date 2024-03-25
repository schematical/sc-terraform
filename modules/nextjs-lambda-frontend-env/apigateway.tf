module "apigateway_env" {

  source = "../apigateway-env"
  env = var.env
  // vpc_id = var.vpc_id
  // ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  domain_name = var.subdomain
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size = var.cache_cluster_size
  // private_subnet_mappings = var.private_subnet_mappings
}