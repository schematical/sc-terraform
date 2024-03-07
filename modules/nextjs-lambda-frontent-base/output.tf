
output "aws_route53_zone_id" {
  value = aws_route53_zone.domain_name_com.id
}
output "aws_route53_zone_name" {
  value = aws_route53_zone.domain_name_com.name
}
output "aws_apigateway_rest_api_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}
output "aws_acm_certificate_arn" {
  value = aws_acm_certificate.aws_acm_certificate.arn
}
output "aws_api_gateway_rest_api_root_resource_id" {
  value = aws_api_gateway_rest_api.api_gateway.root_resource_id
}