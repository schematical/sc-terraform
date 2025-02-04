data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_cloudtrail" "cloudtrail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_s3_bucket_policy]

  name                          = "schematical-2"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_s3_bucket.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = false
}

resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
  bucket        = "schematical-2-cloudtrail"
  force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail_iam_policy_document" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_s3_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/schematical-2"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_s3_bucket.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

   condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/schematical-2"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_s3_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_s3_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_iam_policy_document.json
}

