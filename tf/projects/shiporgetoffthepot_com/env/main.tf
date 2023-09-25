
module "prod_env_shiporgetofthepot_com_tg" {
  source = "../../../../modules/alb-ecs-service-association"
  env = "prod"
  vpc_id = var.env_info.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.env_info.private_subnet_mappings
  acm_cert_arn = var.acm_cert_arn
  codepipeline_artifact_store_bucket = var.env_info.codepipeline_artifact_store_bucket
  domain_name = "www"

  secrets = var.env_info.secrets
  alb_arn = var.env_info.shared_alb.alb_arn
  alb_dns_name = var.env_info.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.shared_alb.alb_hosted_zone_id
}
module "prod_env_shiporgetofthepot_com_ecs_service" {
  source = "../../../../modules/ecs-service"
  env = "prod"
  vpc_id = var.env_info.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.env_info.private_subnet_mappings
  aws_lb_target_group_arn = module.prod_env_shiporgetofthepot_com_tg.aws_lb_target_group_arn
  ecs_cluster = var.env_info.ecs_cluster.id
  ingress_security_groups = [
    var.env_info.shared_alb.alb_sg_id
  ]
}
module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "shiporgetoffthepot-com-v1"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "shiporgetoffthepot-com"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "buildspec.yml"
  env_vars = {
    DB_URL: var.env_info.rds_instance
  }

}
