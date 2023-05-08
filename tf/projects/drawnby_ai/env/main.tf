
module "cloudfront" {
  service_name = var.project_name
  source = "../../../../modules/cloudfront"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  api_gateway_id = var.api_gateway_id
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
}


