output "apigateway_env_api_gateway_base_path_mapping" {
  value = module.apigateway_env.api_gateway_base_path_mapping
}
output "iam_role_name" {
  value = module.lambda_service.iam_role.name
}
output "lambda_function_name" {
  value = module.lambda_service.lambda_function.function_name
}
output "lambda_security_group_id" {
  value = module.lambda_service.lambda_sg_id
}
output "api_gateway_stage_id" {
  value = module.apigateway_env.api_gateway_stage_id
}