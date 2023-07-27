
output "api_gateway_stage_id" {
  value = aws_api_gateway_stage.api_gateway_stage.id
}
output "api_gateway_stage_name" {
  value = aws_api_gateway_stage.api_gateway_stage.stage_name
}
output "api_gateway_base_path_mapping" {
  value = aws_api_gateway_base_path_mapping.api_gateway_base_path_mapping.id
}
output "cloudfront_domain_name" {
  value = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
}
output "cloudfront_zone_id" {
  value = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
}

