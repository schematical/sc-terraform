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


resource "aws_ecr_repository" "sagemaker_ecr_repo" {
  name                 = "${var.service_name}-${var.env}-${var.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


data "aws_iam_policy_document" "sagemaker_ecr_repo_policy" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
resource "aws_ecr_repository_policy" "sagemaker_ecr_repo_policy" {
  repository = aws_ecr_repository.sagemaker_ecr_repo.name
  policy     = data.aws_iam_policy_document.sagemaker_ecr_repo_policy.json
}
resource "aws_iam_role" "example" {
  name = "sagemaker_test_role"
  assume_role_policy = data.aws_iam_policy_document.iam_assume_role.json


  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": "*",
          "Condition": {
            "StringEquals": {
              "iam:PassedToService": [
                "sagemaker.amazonaws.com",
              ]
            }
          }
        },
        {
          Action   = [
            "ecr:ListTagsForResource",
            "ecr:ListImages",
            "ecr:DescribeRepositories",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetLifecyclePolicy",
            "ecr:DescribeImageScanFindings",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:GetRepositoryPolicy"
          ]
          Effect   = "Allow"
          Resource = [

            aws_ecr_repository.sagemaker_ecr_repo.arn,
            join(":", [ aws_ecr_repository.sagemaker_ecr_repo.arn, "*"]),
            "arn:aws:ecr:us-east-1:368590945923:repository/dreambooth-worker-v1-prod-us-east-1*" # DELETE ME
          ]
        },
        {
          Action   = [
            "ecr:GetAuthorizationToken",
          ]
          Effect   = "Allow"
          Resource = [
            "*",

          ]
        },
        {
          Action   = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
          ]
          Effect   = "Allow"
          Resource = [
            "arn:aws:logs:us-east-1:368590945923:log-group:/aws/sagemaker/**",
          ]
        },
        {
          Action   = [
            "cloudwatch:PutMetricData"
          ]
          Effect   = "Allow"
          Resource = [
            "*",
          ]
        },
        {
          Action   = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Effect   = "Allow"
          Resource = [
            aws_s3_bucket.output_bucket.arn,
            join("/", [
              aws_s3_bucket.output_bucket.arn,
              "**"
            ]),
            "arn:aws:s3:::sc-cloud-formation-v1", # TODO DELETEME
            "arn:aws:s3:::sc-cloud-formation-v1/**", # TODO DELETEME
            "arn:aws:s3:::sagemaker-us-east-1-368590945923/**", # TODO DELETEME
            "arn:aws:s3:::dreambooth-worker-v1-prod-us-east-1", # TODO DELETEME
            "arn:aws:s3:::dreambooth-worker-v1-prod-us-east-1/**" # TODO DELETEME
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterfacePermission",
            "ec2:DescribeVpcs",
            "ec2:DeleteNetworkInterface",
            "ecr:GetAuthorizationToken",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeDhcpOptions"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "sns:Publish",
          ],
          "Resource": [
            aws_sns_topic.error_topic.arn,
            aws_sns_topic.success_topic.arn
          ]
        }


      ]
    })
  }

}
# terraform apply -target=aws_iam_role.example
data "aws_iam_policy_document" "iam_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}


/*resource "aws_sagemaker_endpoint" "e" {
  name                 = "my-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.ec.name

  tags = {
    Name = "foo"
  }

}*/
resource "aws_sagemaker_endpoint_configuration" "ec" {
  name = "my-endpoint-config"

  production_variants {
    variant_name           = "variant-1"
    model_name             = aws_sagemaker_model.model1.name
    initial_instance_count = 1
    instance_type          = "ml.g4dn.xlarge"
    /*serverless_config {
      max_concurrency = 1
      memory_size_in_mb = 6144
    }*/


  }
  async_inference_config {
    client_config {
      max_concurrent_invocations_per_instance = 2
    }
    output_config  {
      s3_output_path = join("", [
        "s3://",
        aws_s3_bucket.output_bucket.bucket
      ])

      notification_config {
        success_topic = aws_sns_topic.success_topic.arn
        error_topic = aws_sns_topic.error_topic.arn
      }
    }

  }

  tags = {
    Name = "foo"
  }
}

resource "aws_sns_topic" "success_topic" {
  name = "sagemaker-success-topic"
}
resource "aws_sns_topic" "error_topic" {
  name = "sagemaker-error-topic"
}
resource "aws_sns_topic_subscription" "error_topic_sub" {
  topic_arn = aws_sns_topic.error_topic.arn
  protocol  = "email-json"
  endpoint  = "mlea+test@schematical.com"
}
resource "aws_sns_topic_subscription" "success_topic_sub" {
  topic_arn = aws_sns_topic.success_topic.arn
  protocol  = "email-json"
  endpoint  = "mlea+test@schematical.com"
}



resource "aws_s3_bucket" "output_bucket" {
  bucket = "schematical-sagemaker-test"

  tags = {
    Name        = "sagemaker_test"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "aws_s3_bucket_acl" {
  bucket = aws_s3_bucket.output_bucket.id
  acl    = "private"
}


resource "aws_sagemaker_model" "model1" {
  name               = "my-model"
  execution_role_arn = aws_iam_role.example.arn

  primary_container {
    image = "368590945923.dkr.ecr.${var.region}.amazonaws.com/${var.service_name}-${var.env}-${var.region}:${var.env}" # "368590945923.dkr.ecr.us-east-1.amazonaws.com/dreambooth-worker-v1-prod-us-east-1:sagemaker"
    # image = data.aws_sagemaker_prebuilt_ecr_image.test.registry_path
    model_data_url = "s3://sagemaker-us-east-1-368590945923/pytorch-inference-2023-03-28-22-59-47-075/model.tar.gz"
  }
  vpc_config {
    subnets            =  [for o in var.private_subnet_mappings : o.id] # var.private_subnet_mappings[*].id
    security_group_ids = [aws_security_group.aws_sagemaker_model_security_group.id]
  }
}
/*data "aws_sagemaker_prebuilt_ecr_image" "test" {
  repository_name = "pytorch-inference"
  image_tag       = "1.8.0-gpu-py3" # "1.13.1-transformers4.26.0-gpu-py39-ubuntu18.04"
}*/
resource "aws_security_group" "aws_sagemaker_model_security_group" {
  name        =  "${var.service_name}-${var.env}-${var.region}"
  description = "${var.service_name}-${var.env}-${var.region}"
  vpc_id      = var.vpc_id

  /*ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }*/

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


module "buildpipeline" {
  source = "../buildpipeline"
  service_name = "sagemaker-test"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "sc-terraform"
  github_source_branch = "main"
  code_pipeline_artifact_store_bucket = var.code_pipeline_artifact_store_bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "modules/sagemaker/build/buildspec.yml"
  # codestar_connection_arn ="arn:aws:codestar-connections:us-east-1:368590945923:connection/67d17ca5-a542-49db-9256-157204b67b1d"
}
