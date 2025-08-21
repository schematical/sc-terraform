resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "schematical-${var.env}-${var.region}"
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = {
    Env = "${var.env}"
    Region = "${var.region}"
  }
}


# Production environment
module "kinesis_analytics_prod" {
  source = "../../../../modules/kinesis-glue-integration"

  project_name       = "schematical"
  environment        = "prod"
  kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
  table_name         = "user_events"

  # Same schema as dev
  table_schema = [
    {
      name = "event_id"
      type = "string"
    },
    {
      name = "timestamp"
      type = "timestamp"
    },
    {
      name = "event_type"
      type = "string"
    },
    {
      name = "user_id"
      type = "string"
    },
    {
      name = "session_id"
      type = "string"
    },
    {
      name = "page_url"
      type = "string"
    },
    {
      name = "user_agent"
      type = "string"
    },
    {
      name = "ip_address"
      type = "string"
    },
    {
      name = "properties"
      type = "string"
    },
    {
      name = "source"
      type = "string"
    }
  ]

  # Production settings - smaller buffer for faster processing
  buffer_size     = 1    # MB
  buffer_interval = 60   # seconds (1 minute)

  convert_to_parquet = true
}
output "prod_analytics_info" {
  value = {
    s3_bucket       = module.kinesis_analytics_prod.s3_bucket_name
    glue_database   = module.kinesis_analytics_prod.glue_database_name
    glue_table      = module.kinesis_analytics_prod.glue_table_name
    firehose_stream = module.kinesis_analytics_prod.firehose_delivery_stream_name
  }
}