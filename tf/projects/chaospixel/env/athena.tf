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
  name               = "chaospixel-${var.env}-${var.region}-firehose"
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
        },
        {
          "Effect": "Allow",
          "Action": [
            "glue:GetTableVersions"
          ],
          "Resource": [
            aws_glue_catalog_database.glue_catalog_database.arn,
            aws_athena_data_catalog.athena_data_catalog.arn,
            "arn:aws:glue:us-east-1:${data.aws_caller_identity.current.account_id}:catalog",
            aws_glue_catalog_table.aws_glue_catalog_table.arn
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
    buffer_interval     = 60
    buffer_size         = 64

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
    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          orc_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.glue_catalog_database.name # aws_athena_database.athena_database.name
        role_arn  = aws_iam_role.firehose_role.arn
        table_name    = aws_glue_catalog_table.aws_glue_catalog_table.name
      }
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
/*resource "aws_athena_database" "athena_database" {
  name   = "chaospixel_${var.env}"
  bucket = aws_s3_bucket.glue_storage_bucket.bucket
}*/
resource "aws_glue_catalog_database" "glue_catalog_database" {
  name = "chaospixel_${var.env}"

  create_table_default_permission {
    permissions = ["SELECT"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}
resource "aws_athena_data_catalog" "athena_data_catalog" {
  name        = "chaospixel_${var.env}"
  description = "Glue based Data Catalog"
  type        = "GLUE"

  parameters = {
    "catalog-id" = aws_glue_catalog_database.glue_catalog_database.catalog_id
  }
}
resource "aws_glue_registry" "glue_registry" { // TODO: Move this to global
  registry_name = "chaospixel_${var.env}"
}
/*resource "aws_glue_schema" "test_glue_schema" {
  schema_name       = "test"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "AVRO"
  compatibility     = "NONE"
  schema_definition = "{\"type\": \"record\", \"name\": \"r1\", \"fields\": [ {\"name\": \"CHANGE\", \"type\": \"float\"}, {\"name\": \"PRICE\", \"type\": \"float\"}, {\"name\": \"TICKER_SYMBOL\", \"type\": \"string\"} ]}"
}*/
resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "chaospixel_${var.env}"
  database_name = aws_glue_catalog_database.glue_catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = aws_s3_bucket.glue_storage_bucket.bucket
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "CHANGE"
      type = "double"
    }

    columns {
      name = "PRICE"
      type = "double"
    }

    columns {
      name    = "TICKER_SYMBOL"
      type    = "string"
      comment = ""
    }
  }
}
/*
resource "aws_glue_crawler" "example" {
  database_name = aws_athena_database.athena_database.name
  name          = "example"
  role          = aws_iam_role.example.arn

  dynamodb_target {
    path = "table-name"
  }
}*/
