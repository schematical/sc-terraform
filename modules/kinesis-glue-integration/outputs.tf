output "s3_bucket_name" {
  description = "Name of the S3 bucket storing the data"
  value       = aws_s3_bucket.data_lake_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing the data"
  value       = aws_s3_bucket.data_lake_bucket.arn
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.data_lake_database.name
}

output "glue_table_name" {
  description = "Name of the Glue table"
  value       = aws_glue_catalog_table.kinesis_events_table.name
}

output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Data Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.kinesis_to_s3.name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Kinesis Data Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.kinesis_to_s3.arn
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup for running queries"
  value       = aws_athena_workgroup.analytics_workgroup.name
}

output "athena_query_example" {
  description = "Example Athena query to query the partitioned data"
  value = <<-EOT
    -- Example Athena queries for your partitioned table:
    
    -- Query recent data (last 24 hours)
    SELECT * FROM ${aws_glue_catalog_database.data_lake_database.name}.${aws_glue_catalog_table.kinesis_events_table.name}
    WHERE year = YEAR(CURRENT_DATE)
      AND month = MONTH(CURRENT_DATE)
      AND day = DAY_OF_MONTH(CURRENT_DATE)
    ORDER BY timestamp DESC
    LIMIT 100;
    
    -- Query specific date range
    SELECT event_type, COUNT(*) as event_count
    FROM ${aws_glue_catalog_database.data_lake_database.name}.${aws_glue_catalog_table.kinesis_events_table.name}
    WHERE year = 2024 
      AND month = 12
      AND day BETWEEN 1 AND 7
    GROUP BY event_type;
    
    -- Query with time-based filtering
    SELECT *
    FROM ${aws_glue_catalog_database.data_lake_database.name}.${aws_glue_catalog_table.kinesis_events_table.name}
    WHERE year = 2024 
      AND month = 12 
      AND day = 15
      AND hour BETWEEN 9 AND 17
    ORDER BY timestamp;
  EOT
}
