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
  default     = "iamservice"
}
variable "service_uri" {
  description = "URI"
  type        = string
  default     = "iamaroute"
}
variable "service_envs" {
  description = "Environment"
  type        = list(string)
  default     = ["dev"]
}

variable "api_gateway_id" {
  description = "The APIGateway Instance Id"
  type        = string
  default     = "sc"
}
variable "api_gateway_parent_id" {
  description = "The APIGateway's Root Resource Id"
  type        = string
  default     = "sc"
}
variable "api_gateway_stage_id" {
  description = "The APIGateway's Stage"
  type        = string
  default     = "sc"
}
variable "vpc_id" {
  description = "The id of the VPC your working with"
  type        = string
  default     = "sc"
}
variable "private_subnet_ids" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = []
}

