resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.env}-v1"

  /*setting {
    name  = "containerInsights"
    value = "enabled"
  }*/
}
resource "aws_iam_role" "task_role" {
  name = "ecs-task-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
/*
resource "aws_iam_policy" "task_iam_policy" {
  name = "explodeme-com-v1-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        */
/*{
          "Sid" : "DynamoDB",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:BatchGetItem"
          ],
          "Resource" : var.dynamodb_table_arns
        }*//*


      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_iam_policy.arn
}
*/


resource "aws_ecr_repository" "ecr_repo" {
  name                 = "explodeme-com-${var.env}-${var.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "env_explode_com_tg" {
  source                              = "../../../modules/alb-ecs-service-association"
  env                                 = var.env
  service_name                        = "explodeme-com"
  vpc_id                              = module.vpc.vpc_id
  hosted_zone_id                      = var.hosted_zone_id
  hosted_zone_name                    = var.hosted_zone_name
  subdomain                           = var.subdomain
  alb_arn                             = module.shared_alb.alb_arn
  alb_dns_name                        = module.shared_alb.alb_dns_name
  alb_hosted_zone_id                  = module.shared_alb.alb_hosted_zone_id
  container_port                      = local.container_port
  alb_target_group_health_check_path  = "/"
  lb_http_listener_arn                = module.shared_alb.lb_http_listener_arn
  lb_https_listener_arn               = module.shared_alb.lb_https_listener_arn
  lb_listener_rule_http_rule_priority = var.env == "prod" ? 1 : 2
}
module "env_explode_com_ecs_service" {
  source                  = "../../../modules/ecs-service"
  env                     = var.env
  vpc_id                  = module.vpc.vpc_id
  service_name            = "explodeme-com"
  ecs_desired_task_count  = 1
  private_subnet_mappings = module.vpc.private_subnet_mappings
  aws_lb_target_group_arns = [module.env_explode_com_tg.aws_lb_target_group_arn]
  ecs_cluster_id          = aws_ecs_cluster.ecs_cluster.id
  ingress_security_groups = [
    module.shared_alb.alb_sg_id
  ]
  ecr_image_uri                    = "${aws_ecr_repository.ecr_repo.repository_url}:${var.env}"
  container_port                   = local.container_port
  create_secrets                   = false
  task_role_arn                    = aws_iam_role.task_role.arn
  task_definition_environment_vars = [
    {
      name : "NODE_ENV ",
      value : var.env
    },
    {
      name : "ENV",
      value : var.env
    },
    {
      name : "NEXT_PUBLIC_SERVER_URL",
      value : local.NEXT_PUBLIC_SERVER_URL
    },
    /*{
      name : "AUTH_CLIENT_ID",
      value : var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    },
    {
      name : "AUTH_USER_POOL_ID",
      value : var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    },*/
    {
      name : "S3_BUCKET",
      value : module.cloudfront.s3_bucket.bucket
    },
    {
      name : "PUBLIC_ASSET_URL",
      value : local.PUBLIC_ASSET_URL
    },
  ]
  container_name = var.service_name
}
