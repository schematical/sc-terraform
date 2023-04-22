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
    instance_type           = var.instance_types
    max_vcpus                = var.max_vcpus
    min_vcpus                = var.min_vcpus
    security_group_ids       = [aws_security_group.batch_gpu_compute_environment_security_group.id]
    subnets                  = [for o in var.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
    type                     = "EC2"
    ec2_key_pair = "schematical_node_1"
    # update_to_latest_image   = true

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

  /*update_policy {
    job_execution_timeout_minutes = 30
    terminate_jobs_on_update      = false
  }*/

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
  name = join("-", [var.service_name, var.env, var.region, "cpu-env"])
  role = aws_iam_role.batch_gpu_compute_environment.name
}

resource "aws_iam_role" "batch_gpu_compute_environment" {
  name               = join("-", [var.service_name, var.env, var.region, "compute-env"])
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

  path = "/"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
  inline_policy {
    name = "my_inline_policy"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Resource = aws_efs_file_system.efs_file_system.arn
          Action   = "elasticfilesystem:DescribeMountTargets"
        }
      ]
    })
  }
  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}


resource "aws_security_group" "batch_gpu_compute_environment_security_group" {
  name_prefix = "${var.service_name}-${var.env}-${var.region}-"
  description = "${var.service_name}-${var.env}-${var.region}"
  vpc_id      = var.vpc_id


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
resource "aws_vpc_security_group_ingress_rule" "batch_gpu_compute_environment_security_group_egress_rule" {
  security_group_id = aws_security_group.batch_gpu_compute_environment_security_group.id
  referenced_security_group_id  = var.bastion_security_group
  description       = "AllIPv4"
  from_port         = 22
  ip_protocol          = "tcp"
  to_port           = 22
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
resource "aws_cloudwatch_log_group" "job_definition_log_group" {
  name = join("-", [var.service_name, var.env, var.region])

  tags = {
    Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}
resource "aws_batch_job_definition" "job_definition" {
   type = "container"

   name = "${join("-", [var.service_name, var.env, var.region])}"

   container_properties = jsonencode({
     command = []
     environment = [
       {
         name  = "S3_BUCKET"
         value = var.output_bucket.bucket
       },
       {
         name  = "PYTHONUNBUFFERED"
         value = "1"
       }
     ]
     executionRoleArn = var.ecs_task_execution_iam_role.arn
     jobRoleArn = aws_iam_role.job_definition_iam_role.arn
     image = "${join(":", [aws_ecr_repository.ecr_repository.repository_url, var.env])}"

     logConfiguration = {
       logDriver = "awslogs"

       options = {
         "awslogs-region"        = "${var.region}"
         "awslogs-group"         = aws_cloudwatch_log_group.job_definition_log_group.name # "${join("-", [var.service_name, var.env, var.region])}"
         "awslogs-create-group"  = "true"
       }
     }

     privileged = true

     readonlyRootFilesystem = false

     resourceRequirements = [
       {
         type  = "GPU"
         value = "1"
       },
       {
         type  = "VCPU"
         value = "8"
       },
       {
         type  = "MEMORY"
         value = "30510"
       }
    ]
     mountPoints = [
       {
         containerPath = "/home/ubuntu/src"
         sourceVolume  = "src"
         readOnly      = false
       },
       {
         containerPath = "/home/ubuntu/.conda"
         sourceVolume  = "conda_cache"
         readOnly      = false
       },
       {
         containerPath = "/root/.cache"
         sourceVolume  = "root_cache"
         readOnly      = false
       },
       {
         containerPath = "/home/ubuntu/.cache"
         sourceVolume  = "ubuntu_cache"
         readOnly      = false
       },
       {
         containerPath = "/opt/conda"
         sourceVolume  = "opt_conda"
         readOnly      = false
       }
     ]

     volumes = [
       {
         name = "root_cache"

         efsVolumeConfiguration  = {
           fileSystemId = "${aws_efs_file_system.efs_file_system.id}"
           rootDiirectory = "/root_cache"
         }
       },
       {
         name = "opt_conda"

         efsVolumeConfiguration = {
           fileSystemId = "${aws_efs_file_system.efs_file_system.id}"
           rootDiirectory = "/opt_conda"
         }
       },
       {
         name = "src"

         efsVolumeConfiguration = {
           fileSystemId = "${aws_efs_file_system.efs_file_system.id}"
           rootDiirectory = "/src"
         }
       },
       {
         name = "ubuntu_cache"

         efsVolumeConfiguration = {
           fileSystemId = "${aws_efs_file_system.efs_file_system.id}"
           rootDiirectory = "/ubuntu_cache"
         }
       },
       {
         name = "conda_cache"

         efsVolumeConfiguration = {
           fileSystemId = "${aws_efs_file_system.efs_file_system.id}"
           rootDiirectory = "/conda_cache"
         }
       }
     ]
   })

   parameters = {}

   platform_capabilities = ["EC2"]

   tags = {
     Service = "${var.service_name}"
     Env     = "${var.env}"
     Region  = "${var.region}"
   }

   timeout {
     attempt_duration_seconds = 3000
   }
 }
 resource "aws_iam_role" "job_definition_iam_role" {
   name = "${join("-", [var.service_name, "task-execution", var.env, var.region])}"
   path = "/"
   assume_role_policy = jsonencode({
     Version = "2012-10-17"
     Statement = [
       {
         Effect = "Allow"
         Principal = {
           Service = "ecs-tasks.amazonaws.com"
         }
         Action = "sts:AssumeRole"
       }
     ]
   })
   inline_policy {
     name   = "my_inline_policy"
     policy = jsonencode({
       Version   = "2012-10-17"
       Statement = [
         {
           Effect = "Allow"
           Action = [
             "s3:PutObject",
             "s3:GetObject",
             "s3:GetObjectVersion",
             "s3:GetBucketAcl",
             "s3:GetBucketLocation"
           ]
           Resource = [
             "${var.output_bucket.arn}/**",
             "${var.output_bucket.arn}"
           ]
         },
         {
           Effect = "Allow"
           Action = [
             "logs:CreateLogGroup",
             "logs:CreateLogStream",
             "logs:PutLogEvents"
           ]
           Resource = [
             "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${join("", [var.service_name, "-", var.env, "-", var.region])}:*",
             "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${join("", [var.service_name, "-", var.env, "-", var.region])}:**"
           ]
         }
       ]
     })
   }
 }

resource "aws_batch_job_queue" "batch_job_queue" {
  name        = "${var.service_name}-${var.env}-${var.region}"
  priority    = 1
  state       = "ENABLED"

  compute_environments = [
    aws_batch_compute_environment.batch_gpu_compute_environment.arn
  ]

  tags = {
    Service = "${var.service_name}"
    Env     = "${var.env}"
    Region  = "${var.region}"
  }
}



resource "aws_efs_file_system" "efs_file_system" {
  encrypted         = false
  performance_mode  = "generalPurpose"
  throughput_mode   = "bursting"

  tags = {
    Service = "${var.service_name}"
    Env     = "${var.env}"
    Region  = "${var.region}"
  }
}

resource "aws_efs_file_system_policy" "efs_file_system_policy" {
  file_system_id = aws_efs_file_system.efs_file_system.id

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["elasticfilesystem:Client*"],
      Principal: {"AWS": "*"}
    }]
  })
}
resource "aws_efs_access_point" "efs_file_system_access_point_resource" {
  file_system_id = aws_efs_file_system.efs_file_system.id

  posix_user {
    uid = "13234"
    gid = "1322"
    secondary_gids = ["1344", "1452"]
  }

  root_directory {
    creation_info {
      owner_gid = "708798"
      owner_uid = "7987987"
      permissions = "0755"
    }
    path = "/"
  }
}
resource "aws_security_group" "efs_mount_target_security_group" {
  name_prefix = "${var.service_name}-efs-mount-target-${var.env}-${var.region}"
  description = "${var.service_name}-efs-mount-target-${var.env}-${var.region}"
  vpc_id = var.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = [aws_security_group.batch_gpu_compute_environment_security_group.id] # , aws_security_group.code_build_security_group.id
    description = "AllIPv4"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_efs_mount_target" "efs_mount_target_private_subnet" {
  for_each = {
    for index, vm in var.private_subnet_mappings:
    vm.id => vm # Perfect, since VM names also need to be unique
    # OR: index => vm (unique but not perfect, since index will change frequently)
    # OR: uuid() => vm (do NOT do this! gets recreated everytime)
  }
  file_system_id = aws_efs_file_system.efs_file_system.id
  security_groups = [
    aws_security_group.efs_mount_target_security_group.id
  ]
  subnet_id = each.value.id
}

resource "aws_s3_bucket_policy" "CodePipelineArtifactStoreBucketPolicy" {
  bucket = var.codepipeline_artifact_store_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "S3"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource  = var.codepipeline_artifact_store_bucket.arn

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}
module "buildpipeline" {
  source = "../buildpipeline"
  service_name = var.service_name
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "sc-terraform"
  github_source_branch = "main"
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "modules/aws-batch-pytorch-gpu-service/build/buildspec.yml"
  # codestar_connection_arn ="arn:aws:codestar-connections:us-east-1:368590945923:connection/67d17ca5-a542-49db-9256-157204b67b1d"
}
