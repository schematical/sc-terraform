
output "lambda_security_group_id" {
  value = module.nextjs_lambda.lambda_security_group_id
}
output "apigateway_env_api_gateway_base_path_mapping" {
  value = module.nextjs_lambda.apigateway_env_api_gateway_base_path_mapping
}