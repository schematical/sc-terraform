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
variable "lb_http_listener_arn" {
  type    = string
}
variable "lb_https_listener_arn" {
  type    = string
}
variable "lb_listener_rule_http_rule_priority" {
  type    = number
  default = 99
}


variable "alb_target_group_health_check_path" {
  type    = string
  default = "/heartbeat"
}
variable "container_port" {
  type    = number
  default = 80
}
variable "health_interval" {
  type    = number
  default = 30
}
variable "health_threshold" {
  type    = number
  default = 3
}
variable "health_timeout" {
  type    = number
  default = 5
}
/*
variable "acm_cert_arn" {
  type    = string
}
*/
