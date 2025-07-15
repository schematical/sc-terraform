

output "task_security_group_id" {
  value = module.env_schematical_com_ecs_service.task_security_group_id
  # value = module.nextjs_lambda.lambda_security_group_id
}
/*
output "apigateway_env_api_gateway_base_path_mapping" {
  value = module.nextjs_lambda.apigateway_env_api_gateway_base_path_mapping
}*/

output "target_group_arn" {
  value = module.env_schematical_com_tg.aws_lb_target_group_arn
  # value = module.nextjs_lambda.lambda_security_group_id
}