data "aws_caller_identity" "current" {}
locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:schematical-com-v1-$${stageVariables.ENV}-www/invocations"
}
provider "aws" {
  region = "us-east-1"
  # alias  = "east"
}
resource "aws_ses_domain_identity" "example" {
  domain = "example.com"
}

resource "aws_ses_receipt_rule" "store" {
  name          = "store"
  rule_set_name = "default-rule-set"
  recipients    = ["karen@example.com"]
  enabled       = true
  scan_enabled  = true

  add_header_action {
    header_name  = "Custom-Header"
    header_value = "Added by SES"
    position     = 1
  }

  lambda_action {
    bucket_name = "emails"
    position    = 2
  }
}