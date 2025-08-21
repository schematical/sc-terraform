# Kinesis to Glue Database Integration Module

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # Use latest 6.x version
    }
  }
}

locals {
  # Ensure buffer size meets AWS requirements when data format conversion is enabled
  effective_buffer_size = var.convert_to_parquet ? max(var.buffer_size, 64) : var.buffer_size
}

# S3 bucket for storing the data
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket = "${var.project_name}-data-lake-${var.environment}"
}
/*
resource "aws_s3_bucket_versioning" "data_lake_bucket_versioning" {
  bucket = aws_s3_bucket.data_lake_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_bucket_encryption" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}*/

# Glue Database
resource "aws_glue_catalog_database" "data_lake_database" {
  name        = "${var.project_name}_${var.environment}_database"
  description = "Database for ${var.project_name} data lake in ${var.environment}"
}

# Glue Table with partitioning and Athena partition projection
resource "aws_glue_catalog_table" "kinesis_events_table" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.data_lake_database.name
  description   = "Table for Kinesis events with date-hour partitioning"

  table_type = "EXTERNAL_TABLE"

  # Athena partition projection - no crawler needed!
  parameters = {
    "classification"                   = var.convert_to_parquet ? "parquet" : "json"
    "compressionType"                 = "gzip"
    "typeOfData"                      = "file"
    "has_encrypted_data"              = "false"
    
    # Enable partition projection for automatic partition discovery
    "projection.enabled"              = "true"
    "projection.year.type"            = "integer"
    "projection.year.range"           = "2020,2030"
    "projection.month.type"           = "integer"
    "projection.month.range"          = "1,12"
    "projection.month.digits"         = "2"
    "projection.day.type"             = "integer"
    "projection.day.range"            = "1,31"
    "projection.day.digits"           = "2"
    "projection.hour.type"            = "integer"
    "projection.hour.range"           = "0,23"
    "projection.hour.digits"          = "2"
    
    # Template for partition locations
    "storage.location.template"       = "s3://${aws_s3_bucket.data_lake_bucket.bucket}/${var.table_name}/year=$${year}/month=$${month}/day=$${day}/"
  }

  # Define partition keys
  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  partition_keys {
    name = "day"
    type = "int"
  }



  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_lake_bucket.bucket}/${var.table_name}/"
    input_format  = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat" : "org.apache.hadoop.mapred.TextInputFormat"
    output_format = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat" : "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe" : "org.openx.data.jsonserde.JsonSerDe"
      parameters = var.convert_to_parquet ? {} : {
        "serialization.format" = "1"
      }
    }

    # Define schema columns
    dynamic "columns" {
      for_each = var.table_schema
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
  }


}

# IAM role for Kinesis Data Firehose
resource "aws_iam_role" "firehose_delivery_role" {
  name = "${var.project_name}-firehose-delivery-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Kinesis Data Firehose
resource "aws_iam_role_policy" "firehose_delivery_policy" {
  name = "${var.project_name}-firehose-delivery-policy-${var.environment}"
  role = aws_iam_role.firehose_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.data_lake_bucket.arn,
          "${aws_s3_bucket.data_lake_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CloudWatch Log Group for Firehose
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}

# Kinesis Data Firehose Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "kinesis_to_s3" {
  name        = "${var.project_name}-kinesis-to-s3-${var.environment}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn          = aws_iam_role.firehose_delivery_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.data_lake_bucket.arn
    prefix             = "${var.table_name}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/"
    
    # Buffer configuration - correct parameter names for extended_s3_configuration
    buffering_size     = local.effective_buffer_size
    buffering_interval = var.buffer_interval
    
    # When using data format conversion to Parquet, compression must be UNCOMPRESSED at S3 level
    # Parquet handles compression internally
    compression_format = var.convert_to_parquet ? "UNCOMPRESSED" : "GZIP"

    # Data transformation (optional)
    dynamic "processing_configuration" {
      for_each = var.enable_data_transformation ? [1] : []
      content {
        enabled = true
        processors {
          type = "Lambda"
          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = var.transformation_lambda_arn
          }
        }
      }
    }

    # CloudWatch logging
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }

    # Data format conversion to Parquet (optional but recommended for analytics)
    dynamic "data_format_conversion_configuration" {
      for_each = var.convert_to_parquet ? [1] : []
      content {
        enabled = true
        
        input_format_configuration {
          deserializer {
            open_x_json_ser_de {}
          }
        }
        
        output_format_configuration {
          serializer {
            parquet_ser_de {}
          }
        }
        
        schema_configuration {
          database_name = aws_glue_catalog_database.data_lake_database.name
          table_name    = aws_glue_catalog_table.kinesis_events_table.name
          role_arn      = aws_iam_role.firehose_delivery_role.arn
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Optional: Create specific partitions if needed (useful for historical data)
resource "aws_glue_partition" "predefined_partitions" {
  count         = length(var.predefined_partitions)
  database_name = aws_glue_catalog_database.data_lake_database.name
  table_name    = aws_glue_catalog_table.kinesis_events_table.name

  partition_values = [
    tostring(var.predefined_partitions[count.index].year),
    format("%02d", var.predefined_partitions[count.index].month),
    format("%02d", var.predefined_partitions[count.index].day)
  ]

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_lake_bucket.bucket}/${var.table_name}/year=${var.predefined_partitions[count.index].year}/month=${format("%02d", var.predefined_partitions[count.index].month)}/day=${format("%02d", var.predefined_partitions[count.index].day)}/"
    input_format  = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat" : "org.apache.hadoop.mapred.TextInputFormat"
    output_format = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat" : "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = var.convert_to_parquet ? "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe" : "org.openx.data.jsonserde.JsonSerDe"
      parameters = var.convert_to_parquet ? {} : {
        "serialization.format" = "1"
      }
    }

    dynamic "columns" {
      for_each = var.table_schema
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
  }
}
