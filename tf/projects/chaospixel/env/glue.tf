data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  inline_policy {
    name = "my_inline_policy"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = [
            aws_cloudwatch_log_group.firehose_log_group.arn,
            "${aws_cloudwatch_log_group.firehose_log_group.arn}/**",
            aws_cloudwatch_log_stream.firehose_log_stream.arn,
            "${aws_cloudwatch_log_stream.firehose_log_stream.arn}/**",
            "*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "kinesis:DescribeStream",
            "kinesis:*"
          ]
          Resource = [
            aws_kinesis_stream.kinesis_stream.arn
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetObject",
            "s3:ListObjects"
          ],
          "Resource": [
            aws_s3_bucket.glue_storage_bucket.arn,
            "${aws_s3_bucket.glue_storage_bucket.arn}/**"
          ]
        }
      ]
    })
  }
}
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name = "chaospixel-${var.env}-${var.region}-glue"

  tags = {
    # Service = var.service_name
    Env     = var.env
    Region  = var.region
  }
}
resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "chaospixel-${var.env}-${var.region}-glue"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}
resource "aws_s3_bucket" "glue_storage_bucket" {
  bucket = "chaospixel-${var.env}-${var.region}-glue"
}
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "chaospixel-${var.env}-${var.region}"
  destination = "extended_s3"
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.glue_storage_bucket.arn
    buffer_interval     = 30
    buffer_size         = 1
    # buffering_size = 64
    # buffering_interval = 30
    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    /*dynamic_partitioning_configuration {
      enabled = "true"
    }*/

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    # prefix              = "data/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    cloudwatch_logging_options {
      enabled = true
      log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name

    }
    /*processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{customer_id:.customer_id}"
        }
      }
    }*/
  }
}