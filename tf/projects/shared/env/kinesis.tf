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
