variable "service_name" {
  type    = string
  default = "sc-ecs-service"
}
variable "alb_idle_timeout" {
  type = number
  default = 60
}

/*variable "hosted_zone_name" {
  type    = string
  default = "schematical.com."
}*/
variable "env" {
  type    = string
  default = "stage"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  description = "The id of the VPC your working with"
  type        = string
}


variable "acm_cert_arn" {
  type = string
}
variable "public_subnet_mappings" {
  type = map(any)
}
/*
variable "alb_target_group_health_check_path" {
  type    = string
  default = "/heartbeat"
}
*/
variable "load_balancer_type" {
  type = string
  default = "application"
}
variable "fixed_message_body" {
  default = "Hello World"
  type = string
}
variable "fixed_content_type" {
  default = "text/html"
  type = string
}