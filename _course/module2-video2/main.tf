data "aws_caller_identity" "current" {}

terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.76.0"
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
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "joes-first-bucket-9471"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
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


data "aws_iam_policy_document" "iam_policy_document_joe" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [
      "*"
    ]
  }
  /*statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [
      aws_kms_key.example.arn
    ]
  }*/
}
resource "aws_iam_user_policy" "iam_policy_document_joe" {
  name   = "joe_user_policy"
  user   = aws_iam_user.iam_user_joe.name
  policy = data.aws_iam_policy_document.iam_policy_document_joe.json
}



resource "aws_kms_key" "example" {
  description             = "An example symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20

}


resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.example.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = "test.jpeg"
  source = "/mnt/c/Users/mlea/Pictures/BJJSlam.jpeg"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("/mnt/c/Users/mlea/Pictures/BJJSlam.jpeg")
}