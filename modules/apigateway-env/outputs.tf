output "api_gateway_stage_id" {
  value = aws_api_gateway_stage.api_gateway_stage.id
}
output "api_gateway_base_path_mapping" {
  value = aws_api_gateway_base_path_mapping.api_gateway_base_path_mapping.id
}
/*output "codepipeline_artifact_store_bucket" {
  value = aws_s3_bucket.codepipeline_artifact_store_bucket
}*/

