data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

resource "aws_route53_zone" "shiporgetoffthepot_com" {
  name = "shiporgetoffthepot.com"
}
/*resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.shiporgetoffthepot_com.zone_id
  name    = "_b39a0a8db6ad4e4e9228c30c7c067586.schematical.com."
  type    = "CNAME"

}*/


/*
module "prod_env_shiporgetoffthepot_com" {
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.prod.vpc_id
  hosted_zone_id = aws_route53_zone.shiporgetoffthepot_com.id
  hosted_zone_name = aws_route53_zone.shiporgetoffthepot_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.env_info.prod.private_subnet_mappings
  codepipeline_artifact_store_bucket = var.env_info.prod.codepipeline_artifact_store_bucket

  subdomain = "www"

  secrets = var.env_info.prod.secrets
  env_info = var.env_info.prod
}
*/
