variable "service_name" {
  type    = string
  default = "sc-ecs-service"
}

variable "hosted_zone_id" {
  type    = string
}
variable "hosted_zone_name" {
  type    = string
  default = "schematical.com."
}
variable "env" {
  type    = string
  default = "stage"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "subdomain" {
  type    = string
}
variable "vpc_id" {
  description = "The id of the VPC your working with"
  type        = string
}
variable "alb_arn" {
  type    = string
}
variable "alb_hosted_zone_id" {
  type    = string
}
variable "alb_dns_name" {
  type    = string
}
variable "acm_cert_arn" {
  type = string
}

variable "alb_target_group_health_check_path" {
  type    = string
  default = "/heartbeat"
}
