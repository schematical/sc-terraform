data "aws_caller_identity" "current" {}


resource "aws_security_group" "task_security_group" {
  name        = "${var.service_name}-v1-${var.env}-ecs"
  description = "${var.service_name}-v1-${var.env}-ecs"

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = var.ingress_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = var.vpc_id
}


resource "aws_secretsmanager_secret" "secret_manager_secret" {
  count = var.create_secrets ? 1 : 0
  description = "${var.service_name}-${var.region}-v1-${var.env}-task"
  name        = "${var.service_name}-${var.region}-v1-${var.env}-task"
  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}

resource "aws_secretsmanager_secret_version" "secretsmanager_secret_version" {
  count = var.create_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret_manager_secret[0].id
  secret_string = jsonencode({ foo: "bar" })
}

resource "aws_cloudwatch_log_group" "ecs_task_log_group" {
  name              = "${var.service_name}-${var.region}-v1-${var.env}"
  retention_in_days = var.retention_in_days
}
locals {
  baseSecrets = var.create_secrets ? [
    {
      name      = "CONFIG"
      valueFrom = aws_secretsmanager_secret.secret_manager_secret[0].arn
    }
  ] : []
}


resource "aws_iam_role" "task_iam_role" {
  name = "${var.service_name}-${var.region}-v1-${var.env}-ecs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  dynamic "inline_policy" {
    for_each = local.baseSecrets
    content {
      name   = "my_inline_policy"
      policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Resource = aws_secretsmanager_secret.secret_manager_secret[0].arn
            Action   = "secretsmanager:GetSecretValue"
          }
        ]
      })
    }

  }
  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.service_name}-${var.region}-v1-${var.env}-container"
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  execution_role_arn       = aws_iam_role.task_iam_role.arn

  cpu    = var.task_cpu
  memory = var.task_memory

  container_definitions = jsonencode([{
    name  = var.service_name
    image = var.ecr_image_uri

    cpu    = var.task_cpu
    memory = var.task_memory

    essential = true

    secrets = concat(
      tolist(local.baseSecrets),
      tolist(var.extra_secrets)
    )

    portMappings  = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol       = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options    = {
        "awslogs-group" = aws_cloudwatch_log_group.ecs_task_log_group.name
        "awslogs-region" = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "ecs_service" {
  name    = "${var.service_name}-${var.region}-v1-${var.env}"
  cluster = var.ecs_cluster_id

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50


  deployment_controller {
    type = "ECS"
  }

  desired_count              = var.ecs_desired_task_count
  health_check_grace_period_seconds  = 60
  launch_type                = var.launch_type

  network_configuration {
    assign_public_ip = false
    security_groups = concat(
      tolist([aws_security_group.task_security_group.id]),
      tolist(var.extra_security_groups)
    )
    subnets         = [for o in var.private_subnet_mappings : o.id]
  }

  load_balancer {
    container_name   = var.service_name
    container_port   = var.container_port
    target_group_arn = var.aws_lb_target_group_arn
  }

  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
}
