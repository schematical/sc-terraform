variable "region" {
  default = "us-east-1"
}


variable "ecs_task_execution_iam_role" {}

/*
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "codepipeline_artifact_store_bucket" {}
*/

variable env_info {
  type = map(object({
    name                               = string
    vpc_id                             = string
    private_subnet_mappings            = map(any)
    codepipeline_artifact_store_bucket = object({
      arn: string
      bucket: string
    })
    api_gateway_stage_id = string
    bastion_security_group = string
    secrets  = map(string)
    shared_alb = object({
      alb_sg_id: string
      alb_arn: string
      alb_hosted_zone_id: string
      alb_dns_name: string
    })
    ecs_cluster = object({
      arn: string
      id: string
    })
    rds_instance = object({
      address: string
    })

  }))
}

