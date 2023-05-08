variable "service_prefix" {
  description = "2 letter prefix"
  type        = string
  default     = "sc"
}
variable "service_version" {
  description = "Service Version"
  type        = string
  default     = "v1"
}
variable "service_name" {
  description = "Name of Service"
  type        = string
}
variable "service_uri" {
  description = "URI"
  type        = string
}
variable "env" {
  description = "Environment"
  type        = string
}
variable "region" {
  description = "Region"
  type        = string
}

variable "api_gateway_id" {
  description = "The APIGateway Instance Id"
  type        = string
}
variable "api_gateway_parent_id" {
  description = "The APIGateway's Root Resource Id"
  type        = string
}
variable "api_gateway_stage_id" {
  description = "The APIGateway's Stage"
  type        = string
}
variable "vpc_id" {
  description = "The id of the VPC your working with"
  type        = string
}
variable "private_subnet_mappings" {
  type = map(any)
}

