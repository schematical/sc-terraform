data "aws_caller_identity" "current" {}


resource "aws_security_group" "task_security_group" {
  name        = "${var.service_name}-v1-${var.env}-ecs"
  description = "${var.service_name}-v1-${var.env}-ecs"

  ingress {
    from_port       = 80
    to_port         = 80
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

resource "aws_iam_role" "task_iam_role" {
  name = "${var.service_name}-${var.region}-v1-${var.env}-codebuild"

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

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}

resource "aws_secretsmanager_secret" "secret_manager_secret" {
  description = "${var.service_name}-${var.region}-v1-${var.env}-task"
  name        = "${var.service_name}-${var.region}-v1-${var.env}-task"
  secret_string = jsonencode({
    "hello" : "world"
  })

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}



resource "aws_cloudwatch_log_group" "ecs_task_log_group" {
  name              = "${var.service_name}-${var.region}-v1-${var.env}"
  retention_in_days = 90
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.service_name}-${var.region}-v1-${var.env}-container"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_iam_role.arn

  cpu    = var.task_cpu
  memory = var.task_memory

  container_definitions = jsonencode([{
    name  = var.service_name
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_name}:${var.env}"

    cpu    = var.task_cpu
    memory = var.task_memory

    essential = true

    secrets = [{
      name      = "CONFIG"
      valueFrom = aws_secretsmanager_secret.secret_manager_secret.arn
    }]

    port_mappings = [{
      container_port = 80
      host_port      = 80
      protocol       = "tcp"
    }]

    log_configuration = {
      log_driver = "awslogs"
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
  cluster = var.ecs_cluster

  deployment_configuration {
    maximum_percent         = 100
    minimum_healthy_percent = 50
  }

  deployment_controller {
    type = "ECS"
  }

  desired_count              = var.ecs_desired_task_count
  health_check_grace_period = 60
  launch_type                = "FARGATE"

  network_configuration {
    awsvpc_configuration {
      assign_public_ip = "DISABLED"
      security_groups = [aws_security_group.task_security_group.id]
      subnets         = var.private_subnet_mappings
    }
  }

  load_balancer {
    container_name   = var.service_name
    container_port   = 80
    target_group_arn = var.aws_lb_target_group_arn
  }

  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
}

