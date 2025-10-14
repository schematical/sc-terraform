/*terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}*/
resource "aws_acm_certificate" "shared_acm_cert" {
  domain_name       = "schematical.com"
  subject_alternative_names = ["*.schematical.com"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

module "prod_shared_env" {
  source = "./env"
  env = "prod"
  vpc_id = var.vpc_id
  public_subnet_mappings = var.public_subnet_mappings
  private_subnet_mappings = var.private_subnet_mappings
  shared_acm_cert_arn = aws_acm_certificate.shared_acm_cert.arn
}
/*resource "aws_secretsmanager_secret" "docker_hub_secretsmanager_secret" {
  name = "ecr-pullthroughcache/docker-hub"
}
resource "aws_ecr_pull_through_cache_rule" "docker" {
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = aws_secretsmanager_secret.docker_hub_secretsmanager_secret.arn
}*/