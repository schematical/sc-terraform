variable "service_name" {
  type = string
}
variable "base_domain_name" {
  type = string
}
variable "api_gateway_stage_name" {
  type = string
}
variable "aws_route53_zone_id" {
  type = string
}
variable "region" {
  type = string
  default = "us-east-1"
}