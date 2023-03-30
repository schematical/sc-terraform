output "api_gateway_method_id" {
  # Again, the value is not important because we're just
  # using this for its dependencies.
  value =aws_api_gateway_method.api_gateway_method.id

  # Anything that refers to this output must wait until
  # the actions for azurerm_monitor_diagnostic_setting.example
  # to have completed first.
  depends_on = [aws_api_gateway_method.api_gateway_method]
}
output "module_dev_vpc_private_subnet_mappings" {
  value = module.vpc.private_subnet_mappings
}