variable "service_name" {
  type    = string
  default = "sc-ecs-service"
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

variable "vpc_id" {
  description = "The id of the VPC your working with"
  type        = string
}

variable "ecs_cluster_id" {
  description = "The id of the VPC your working with"
  type        = string
}
variable "private_subnet_mappings" {
  type = map(any)
}

variable "ingress_security_groups" {
  type = list(string)
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "ecs_desired_task_count" {
  type    = number
  default = 0
}

variable "aws_lb_target_group_arn" {
  type    = string
}
variable "ecr_image_uri" {
  type    = string
}
variable "container_port" {
  type    = number
  default = 80
}
variable "extra_secrets" {
  type    = list(object({
    name = string
    valueFrom = string
  }))
  default = []
}
variable "retention_in_days" {
  type    = number
  default = 90
}

