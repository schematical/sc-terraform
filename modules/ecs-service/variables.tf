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

variable "aws_lb_target_group_arns" {
  type    =list(string)
  default = []
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
variable "task_definition_environment_vars" {
  type    = list(object({
    name = string
    value = string
  }))
  default = []
}
variable "retention_in_days" {
  type    = number
  default = 90
}
variable "extra_security_groups" {
  type    = list(string)
  default = []
}
variable "launch_type" {
  default = "FARGATE"
  type = string
}
variable "create_secrets" {
  default = true
  type = bool
}
variable "task_definition_command" {
  default = null
  type    = list(string)
}
variable "task_definition_working_dir" {
  default = null
  type    = string
}
variable "extra_iam_policies" {
  type    = list(string)
  default = []
}
variable "task_role_arn" {
  default = null
  type = string
}

variable "enable_execute_command" {
  type   = bool
  default = false
}
variable "container_name" {
  type   = string
  default = false
}
variable "force_deployment" {
  type   = bool
  default = false
}
variable "deployment_minimum_healthy_percent" {
  type   = number
  default = 50
}
variable "deployment_maximum_percent" {
  type   = number
  default = 100
}
variable "capacity_provider_strategies" {
  type   = list(object({
    base: number,
    capacity_provider: string,
    weight: number
  }))
  default = []
}
