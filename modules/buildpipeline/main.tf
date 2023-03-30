
provider "aws" {
  profile  = "schematical"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}
data "aws_caller_identity" "current" {}
/*
resource "aws_s3_bucket_policy" "code_pipeline_artifact_store_bucket_policy" {
  bucket = var.code_pipeline_artifact_store_bucket # aws_s3_bucket.code_pipeline_artifact_store_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:*"
        Resource = var.code_pipeline_artifact_store_bucket # aws_s3_bucket.code_pipeline_artifact_store_bucket.arn
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}
*/

/*
resource "aws_s3_bucket" "code_pipeline_artifact_store_bucket" {
  bucket = "${var.service_name}-${var.env}-${var.region}-code-pipeline"
}
*/


resource "aws_codepipeline" "app_pipeline" {
  name     = "${join("-", [var.service_name, var.env, var.region])}"
  role_arn = aws_iam_role.code_pipeline_service_role.arn

  artifact_store {
    type     = "S3"
    location = var.code_pipeline_artifact_store_bucket # aws_s3_bucket.code_pipeline_artifact_store_bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name            = "SourceAction"
      category        = "Source"
      owner           = "AWS"
      provider        = "CodeStarSourceConnection"
      version         = "1"
      output_artifacts  = [ "SourceArtifact" ]
      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_project_name}"
        BranchName       = var.github_source_branch
      }
      run_order = 1
    }
  }

  stage {
    name = "Build"

    action {
      name          = "Build"
      category      = "Build"
      owner         = "AWS"
      provider      = "CodeBuild"
      version       = "1"
      input_artifacts = [ "SourceArtifact" ]

      output_artifacts =  [ "BuildArtifact" ]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
      }
      run_order = 1
    }
  }
}



resource "aws_iam_role" "code_pipeline_service_role" {
  name = "${var.service_name}-${var.env}-${var.region}-code-pipeline"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = ["codepipeline.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  path = "/"
  # IAM policy document
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "codestar-connections:UseConnection",
            "codestar-connections:StartOAuthHandshake",
            "codestar-connections:GetInstallationUrl",
            "codestar-connections:GetConnection"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchGetBuildBatches"
          ]
          Resource = [aws_codebuild_project.codebuild_project.arn]
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "codebuild:StartBuildBatch"
          ]
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "iam:PassRole"
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject"
          ]
          Resource = "arn:aws:s3:::${var.code_pipeline_artifact_store_bucket}/*"
        }
      ]
    })
  }
}

resource "aws_codebuild_project" "codebuild_project" {
  name = "${var.service_name}-${var.env}-${var.region}"
  description = "${var.service_name}-${var.env}-${var.region}"
  queued_timeout = 5
  service_role = aws_iam_role.code_build_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image = var.code_build_image_uri
    type = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name = "AWS_DEFAULT_region"
      type = "PLAINTEXT"
      value = var.region
    }
    environment_variable {
      name = "ECS_CONTAINER_NAME"
      type = "PLAINTEXT"
      value = var.service_name
    }
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      type = "PLAINTEXT"
      value = "${data.aws_caller_identity.current.account_id}"
    }
    environment_variable {
      name = "IMAGE_TAG"
      type = "PLAINTEXT"
      value = var.env
    }
    environment_variable {
      name = "IMAGE_REPO_NAME"
      type = "PLAINTEXT"
      value = "${var.service_name}-${var.env}-${var.region}"
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.service_name}-${var.env}-${var.region}"
      status = "ENABLED"
    }
  }
  source {
    type = "CODEPIPELINE"
    buildspec = "modules/sagemaker/build/buildspec.yml"
  }
  build_batch_config {
    service_role = aws_iam_role.code_build_role.arn
    timeout_in_mins = var.code_build_timeout
  }
  tags = {
    env = var.env,
    region = var.region,
    Service = var.service_name
  }
}
resource "aws_iam_role" "code_build_role" {
  name = "${join("-", [var.service_name, var.env, var.region, "codebuild"])}"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["codebuild.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "Name" = "${join("-", [var.service_name, var.env, var.region, "codebuild"])}"
  }
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${join("-", [var.service_name, var.env, var.region])}",
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${join("-", [var.service_name, var.env, var.region])}:**"
          ]
        },
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
            "arn:aws:s3:::${var.code_pipeline_artifact_store_bucket}/*",
            "arn:aws:s3:::${var.code_pipeline_artifact_store_bucket}/"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:Start",
            "codebuild:StartBuild"
          ]
          Resource = [
            "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:project/${join("-", [var.service_name, var.env, var.region])}"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetDownloadUrlForLayer",
            "ecr:ListTagsForResource",
            "ecr:UploadLayerPart",
            "ecr:ListImages",
            "ecr:PutImage",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeImages",
            "ecr:TagResource",
            "ecr:DescribeRepositories",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetRepositoryPolicy",
            "ecr:GetLifecyclePolicy"
          ]
          Resource = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ecr:GetAuthorizationToken"
          ],
          "Resource": "*"
        }
      ]
    })
  }
}