
module "dev_env_chaospixel" {

  source = "./env"
  env = "dev"
  secrets = var.secrets
  vpc_id = var.env_info.dev.vpc_id
  # hosted_zone_id = var.hosted_zone_id
  # hosted_zone_name = var.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role

  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_id = var.api_gateway_id
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  api_gateway_stage_id          = var.env_info.dev.api_gateway_stage_id
  bastion_security_group        = var.env_info.dev.bastion_security_group
}
