variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod, etc.)"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream to consume from"
  type        = string
}

variable "table_name" {
  description = "Name of the Glue table"
  type        = string
  default     = "kinesis_events"
}

variable "table_schema" {
  description = "Schema definition for the Glue table"
  type = list(object({
    name = string
    type = string
  }))
  default = [
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
      name = "properties"
      type = "string"
    },
    {
      name = "source"
      type = "string"
    }
  ]
}

variable "buffer_size" {
  description = "Buffer size in MB for Kinesis Firehose (minimum 64 MB when data format conversion is enabled)"
  type        = number
  default     = 64
  
  validation {
    condition = var.buffer_size >= 1 && var.buffer_size <= 128
    error_message = "Buffer size must be between 1 and 128 MB. When convert_to_parquet is true, minimum is 64 MB."
  }
}

variable "buffer_interval" {
  description = "Buffer interval in seconds for Kinesis Firehose"
  type        = number
  default     = 300
}

variable "enable_data_transformation" {
  description = "Enable data transformation using Lambda"
  type        = bool
  default     = false
}

variable "transformation_lambda_arn" {
  description = "ARN of Lambda function for data transformation"
  type        = string
  default     = ""
}

variable "convert_to_parquet" {
  description = "Convert data to Parquet format for better analytics performance"
  type        = bool
  default     = true
}

variable "predefined_partitions" {
  description = "List of predefined partitions to create"
  type = list(object({
    year  = number
    month = number
    day   = number
  }))
  default = []
}
