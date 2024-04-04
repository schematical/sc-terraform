
module "nextjs_lambda" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../../modules/nextjs-lambda-frontend-env"
  env = var.env
  service_name = "${var.service_name}"
  vpc_id = var.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  private_subnet_mappings = var.private_subnet_mappings
  acm_cert_arn = var.acm_cert_arn
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  subdomain = var.subdomain
  secrets = var.secrets
  github_owner = "schematical"
  github_project_name = "splitgpt"
  source_buildspec_path = "www/buildspec.yml"
}