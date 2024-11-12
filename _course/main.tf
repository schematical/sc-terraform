

terraform {
  backend "s3" {
    profile = "schematical"
    bucket = "schematical-terraform-v1"
    region = "us-east-1"
    key    = "_course/terraform.tfstate"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.42.0"
    }
  }

  required_version = ">= 1.5.7"
}

provider "aws" {
  profile  = "schematical2"
  region = "us-east-1"
  default_tags {
    tags = {
    }
  }
}

resource "aws_iam_user" "iam_user_joe" {
  name = "joe"
  # path = "/system/"

  tags = {
    tag-key = "test"
  }
}

resource "aws_iam_access_key" "iam_user_access_key_joe" {
  user = aws_iam_user.iam_user_joe.name
}
resource "local_file" "private_key" {
  content  = "${aws_iam_access_key.iam_user_access_key_joe.id}\n${aws_iam_access_key.iam_user_access_key_joe.secret}"
  filename = "creds.txt"
}

/*data "aws_iam_policy_document" "iam_policy_document_joe" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}*//*"
    ]
  }
}
resource "aws_iam_user_policy" "iam_policy_document_joe" {
  name   = "joe_user_policy"
  user   = aws_iam_user.iam_user_joe.name
  policy = data.aws_iam_policy_document.iam_policy_document_joe.json
}*/
/*resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.iam_user_joe.name
  policy_arn = aws_iam_policy.s3_list_policy.arn
}*/

resource "aws_iam_policy" "s3_list_policy" {
  name        = "s3_list_policy"
  path        = "/"
  description = "S3 List Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:CreateBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketTagging",
          "s3:GetBucketPolicy",
          "s3:*",
          "lambda:CreateFunction",
          "lambda:InvokeFunction",
          "lambda:DeleteFunction",
          "apigateway:CreateRestApi",
          "apigateway:POST",
          "iam:PassRole",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_group" "developers" {
  name = "developers"
  # path = "/users/"
}
resource "aws_iam_group_membership" "team" {
  name = "tf-testing-group-membership"

  users = [
    aws_iam_user.iam_user_joe.name,
  ]

  group = aws_iam_group.developers.name
}
resource "aws_iam_group_policy_attachment" "test-attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_list_policy.arn
}


resource "aws_iam_role" "worker_role" {
  name = "worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      },
    ]
  })

  tags = {

  }
}
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.s3_list_policy.arn
}

