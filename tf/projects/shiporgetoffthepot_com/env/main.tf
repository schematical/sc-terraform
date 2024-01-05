resource "aws_ecr_repository" "prod_ecr_repo" {
  name                 = "sogotp-com-v1-${var.env}-${var.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
module "prod_env_shiporgetoffthepot_com_tg" {
  source = "../../../../modules/alb-ecs-service-association"
  env = "prod"
  service_name = "sogotp-com"
  vpc_id = var.env_info.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  subdomain = var.subdomain
  alb_arn = var.env_info.shared_alb.alb_arn
  alb_dns_name = var.env_info.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.shared_alb.alb_hosted_zone_id
  container_port = 80
  alb_target_group_health_check_path = "/"
  lb_http_listener_arn =  var.env_info.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.shared_alb_https_listener_arn
}
module "prod_env_shiporgetoffthepot_com_ecs_service" {
  source = "../../../../modules/ecs-service"
  env = "prod"
  vpc_id = var.env_info.vpc_id
  service_name = "sogotp-com-v1"
  ecs_desired_task_count =55
  private_subnet_mappings = var.env_info.private_subnet_mappings
  // aws_lb_target_group_arns = [module.prod_env_shiporgetoffthepot_com_tg.aws_lb_target_group_arn]
  ecs_cluster_id = var.env_info.ecs_cluster.id
  ingress_security_groups = [
    var.env_info.shared_alb.alb_sg_id
  ]
  ecr_image_uri = "${aws_ecr_repository.prod_ecr_repo.repository_url}:${var.env}"
  container_port = 80
  create_secrets = false
  task_definition_environment_vars = [
    {
      name: "NODE_ENV ",
      value: var.env
    }
  ]
}
module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "sogotp-com-v1"
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
    # DB_URL: var.env_info.rds_instance.address
  }

}
