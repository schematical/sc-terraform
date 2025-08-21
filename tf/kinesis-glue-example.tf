# Example usage of the Kinesis to Glue integration module
# Add this to your main.tf or create a separate file

module "kinesis_analytics_dev" {
  source = "./modules/kinesis-glue-integration"
  
  project_name       = "schematical"
  environment        = "dev"
  kinesis_stream_arn = local.env_info.dev.kinesis_stream_arn
  table_name         = "user_events"
  
  # Define your event schema - customize this based on your actual data structure
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
      type = "string"  # JSON string containing additional event properties
    },
    {
      name = "source"
      type = "string"
    }
  ]
  
  # Firehose configuration
  buffer_size     = 5    # MB
  buffer_interval = 300  # seconds (5 minutes)
  
  # Convert to Parquet for better query performance
  convert_to_parquet = true
  
  # Optional: Create some initial partitions for historical data
  predefined_partitions = [
    {
      year  = 2024
      month = 12
      day   = 15
      hour  = 0
    },
    {
      year  = 2024
      month = 12
      day   = 15
      hour  = 1
    }
  ]
}

# Production environment
module "kinesis_analytics_prod" {
  source = "./modules/kinesis-glue-integration"
  
  project_name       = "schematical"
  environment        = "prod"
  kinesis_stream_arn = local.env_info.prod.kinesis_stream_arn
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

# Output useful information
output "dev_analytics_info" {
  value = {
    s3_bucket           = module.kinesis_analytics_dev.s3_bucket_name
    glue_database       = module.kinesis_analytics_dev.glue_database_name
    glue_table          = module.kinesis_analytics_dev.glue_table_name
    firehose_stream     = module.kinesis_analytics_dev.firehose_delivery_stream_name
    athena_query_example = module.kinesis_analytics_dev.athena_query_example
  }
}

output "prod_analytics_info" {
  value = {
    s3_bucket       = module.kinesis_analytics_prod.s3_bucket_name
    glue_database   = module.kinesis_analytics_prod.glue_database_name
    glue_table      = module.kinesis_analytics_prod.glue_table_name
    firehose_stream = module.kinesis_analytics_prod.firehose_delivery_stream_name
  }
}
