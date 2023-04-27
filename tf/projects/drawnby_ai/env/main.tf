
resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "codebuild-bucket-${var.env}-${var.region}"
}
module "cloudfront" {
  service_name = "drawnby-ai-v1"
  source = "../../../../modules/cloudfront"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  api_gateway_id = var.api_gateway_id
  codepipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket
}



