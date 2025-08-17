terraform {
  backend "s3" {
    bucket = "schematical2-terraform-v1"
    region = "us-east-1"
    key    = "sc-workspaces-explodeme-com-env/terraform.tfstate"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.88.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}
data "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "explodeme-com-codebuild-v1"
}
locals{
  domain_name = "explodeme.com"
  service_name = "explodeme-com"
  container_port = 3000
#  NEXT_PUBLIC_SERVER_URL = "https://${var.subdomain}.${var.hosted_zone_name}"
 # PUBLIC_ASSET_URL = "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
}
data "aws_route53_zone" "explodeme_com_route53_zone" {
  name         = "${local.domain_name}."
}
data "aws_acm_certificate" "explodeme_com_acm_certificate" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}

data "aws_iam_role" "task_execution_iam_role" {
  name = "ECSTaskExecutionIAMRole"
}
data "aws_api_gateway_rest_api" "explodme_com_rest_api" {
  name = "explodeme-com"
}
/*data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}
data "aws_vpc" "default_vpc" {
  id = "vpc-081f2e4a286d83c11"
}*/
resource "aws_codestarconnections_connection" "codestarconnections_connection" {
  name          = "github-connection"
  provider_type = "GitHub"
}
module "nextjs_lambda" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../modules/nextjs-lambda-frontend-env"
  env = var.env
  service_name = "${local.service_name}"
  vpc_id = module.vpc.vpc_id#data.aws_vpc.default_vpc.id
  hosted_zone_id = data.aws_route53_zone.explodeme_com_route53_zone.id
  hosted_zone_name = data.aws_route53_zone.explodeme_com_route53_zone.name
  ecs_task_execution_iam_role = data.aws_iam_role.task_execution_iam_role
  api_gateway_id = data.aws_api_gateway_rest_api.explodme_com_rest_api.id
  private_subnet_mappings = module.vpc.private_subnet_mappings# { for idx, o in data.aws_subnets.default_subnets.ids : idx => { id = o } }
  acm_cert_arn = data.aws_acm_certificate.explodeme_com_acm_certificate.arn
  codepipeline_artifact_store_bucket = data.aws_s3_bucket.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = data.aws_api_gateway_rest_api.explodme_com_rest_api.root_resource_id
  codestar_connection_arn = aws_codestarconnections_connection.codestarconnections_connection.arn
  subdomain = "www"
  secrets = {}
  github_owner = "schematical"
  github_project_name = "explodeme-com"
  source_buildspec_path = "www/buildspec.yml"
  cache_cluster_enabled = false
  cache_cluster_size = "0.5"
  extra_env_vars = {
    # REDIS_HOST: var.redis_host
    # DEBUG: "ioredis:*"
    ENV: var.env

  }
  xray_tracing_enabled = true

}