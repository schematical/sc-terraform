data "aws_caller_identity" "current" {}
locals {
  env = "dev"
  region = "us-east-1a"
}
resource "aws_ecr_repository" "prod_ecr_repo" {
  name                 = "course-com-v1-${local.env}-${local.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
/*module "prod_env_course_com_tg" {
  source = "../../../../modules/alb-ecs-service-association"
  env = "prod"
  service_name = "sogotp-com"
  vpc_id = var.env_info.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  subdomain = var.subdomain
  alb_arn = var.env_info.shared_alb.alb_arn
  alb_dns_name = var.env_info.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.shared_alb.alb_hosted_zone_id
  container_port = 80
  alb_target_group_health_check_path = "/"
  lb_http_listener_arn =  var.env_info.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.shared_alb_https_listener_arn
}*/
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "course-demo"
}








module "prod_env_course_com_ecs_service" {
  source = "../../modules/ecs-service"
  env = local.env
  vpc_id = module.vpc.vpc_id
  service_name = "course-com-v1"
  ecs_desired_task_count = 1
  private_subnet_mappings = module.vpc.private_subnet_mappings
  // aws_lb_target_group_arns = [module.prod_env_course_com_tg.aws_lb_target_group_arn]
  ecs_cluster_id = aws_ecs_cluster.ecs_cluster.id
  ingress_security_groups = [
    // var.env_info.shared_alb.alb_sg_id
  ]
  ecr_image_uri = "${aws_ecr_repository.prod_ecr_repo.repository_url}:${local.env}"
  container_port = 80
  create_secrets = false
  extra_secrets = [
  /*  {
      name      = "SSM_PARAMETER"
      valueFrom = aws_ssm_parameter.secret.arn
    }*/
    {
      name      = "SECRETS_MANAGER"
      valueFrom = aws_secretsmanager_secret.secret_manager_secret.arn
    },
  ]
  task_definition_environment_vars = [
    {
      name: "NODE_ENV ",
      value: local.env
    }
  ]
}









/*



resource "aws_ssm_parameter" "secret" {
  name        = "/production/database/password/master"
  description = "The parameter description"
  type        = "SecureString"
  value       = "Schematical Was Here"

  tags = {
    environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  role = module.prod_env_course_com_ecs_service.ecs_task_execution_iam_role_name
  policy_arn = aws_iam_policy.ssm_param_store_policy.arn
}

resource "aws_iam_policy" "ssm_param_store_policy" {
  name        = "course-demo-ssm-param-store"
  path        = "/"
  description = "course-demo-ssm-param-store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:DescribeParameters"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameters"
        ],
        "Resource":  aws_ssm_parameter.secret.arn
      }
    ]
  })
}
*/












resource "aws_secretsmanager_secret" "secret_manager_secret" {
  description = "course-demo-${local.region}-v1-${local.env}-task-b"
  name        = "course-demo-${local.region}-v1-${local.env}-task-b"
  tags = {
    Service = "course-demo"
    Env     = local.env
    Region  = local.region
  }
}

resource "aws_secretsmanager_secret_version" "secretsmanager_secret_version" {
  secret_id     = aws_secretsmanager_secret.secret_manager_secret.id
  secret_string = jsonencode({ foo: "schematical" })
}
resource "aws_iam_role_policy_attachment" "secret-attach" {
  role = module.prod_env_course_com_ecs_service.ecs_task_execution_iam_role_name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "course-demo-secrets-manager"
  path        = "/"
  description = "course-demo-secrets-manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.secret_manager_secret.arn
        Action   = "secretsmanager:GetSecretValue"
      },
    ]
  })
}
