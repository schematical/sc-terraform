terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.61.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_batch_compute_environment" "batch_gpu_compute_environment" {
  compute_environment_name = join("-", [var.service_name, var.env, var.region])

  compute_resources {
    allocation_strategy      = "BEST_FIT_PROGRESSIVE"
    instance_role            = aws_iam_instance_profile.batch_gpu_compute_environment.arn
    instance_types           = var.instance_types
    max_vcpus                = var.max_vcpus
    min_vcpus                = var.min_vcpus
    security_group_ids       = [aws_security_group.batch_gpu_compute_environment.id]
    subnets                  = var.private_subnets
    type                     = "EC2"
    update_to_latest_image   = true

    ec2_configuration {
      image_type = "ECS_AL2_NVIDIA"
    }

    ec2_configuration {
      image_type = "ECS_AL2"
    }

    tags = {
      Service = var.service_name
      Env     = var.env
      Region  = var.region
    }
  }

  update_policy {
    job_execution_timeout_minutes = 30
    terminate_jobs_on_update      = false
  }

  service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch"
  state        = "ENABLED"

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }

  type = "MANAGED"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "batch_gpu_compute_environment" {
  name = join("-", [var.service_name, var.env, var.region, "batch-gpu-compute-environment"])
  role = aws_iam_role.batch_gpu_compute_environment.arn
}

resource "aws_iam_role" "batch_gpu_compute_environment" {
  name               = join("-", [var.service_name, var.env, var.region, "batch-gpu-compute-environment"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}

resource "aws_security_group" "batch_gpu_compute_environment" {
  name_prefix = join("-", [var.service_name, var.env, var.region, "batch-gpu-compute-environment"])
  vpc_id      = var.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 0
    to_port   = 65535
    cidr_blocks = ["${var.private_subnets}"]
  }

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}
resource "aws_iam_instance_profile" "batch_gpu_compute_environment_instance_profile" {
  name = "${var.service_name}-compute-env-instance-profile-${var.env}-${var.region}"
  path = "/"

  roles = [aws_iam_role.batch_gpu_compute_environment_instance_iam_role.name]
}

resource "aws_iam_role" "batch_gpu_compute_environment_instance_iam_role" {
  name = "${var.ServiceName}-compute-env-instance-${var.Env}-${var.Region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  path = "/"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Resource  = aws_efs_file_system.EFSFileSystem.arn
        Action    = "elasticfilesystem:DescribeMountTargets"
      }
    ]
  })
}
resource "aws_security_group" "batch_gpu_compute_environment_security_group" {
  name_prefix = "${var.ServiceName}-${var.Env}-${var.Region}-"
  description = "${var.ServiceName}-${var.Env}-${var.Region}"
  vpc_id      = var.VpcId

  ingress = []

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = "AllIPv4"
      from_port        = -1
      protocol         = "-1"
      to_port          = -1
    }
  ]
}
resource "aws_ecr_repository" "ecr_repository" {
  name             = "${var.service_name}-${var.env}-${var.region}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}