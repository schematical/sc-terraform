locals {
  base_domain = "serverdemolitionleague.com"
  domain = var.env == "prod" ? local.base_domain : "${var.env}.${local.base_domain}"
  inbox_table_name = "TenantInbox"
  message_table_name = "TenantInboxMessage"
  lambda_name = "${var.service_name}-${var.env}-inboundEmail"
}


data "aws_route53_zone" "primary" {
  name         = local.base_domain
  private_zone = false
}

resource "aws_ses_domain_identity" "domain" {
  domain = local.domain
}

resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "_amazonses.${local.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.domain.verification_token]
}

resource "aws_ses_domain_identity_verification" "verify" {
  domain     = aws_ses_domain_identity.domain.id
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "ses_mx" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.domain
  type    = "MX"
  ttl     = 600
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../../modules/lambda-service/build"
  output_path = "${path.module}/dist.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.lambda_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamo" {
  name = "lambda-dynamo-access"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ]
      Resource = [
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.inbox_table_name}",
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.inbox_table_name}/index/*",
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.message_table_name}"
      ]
    }]
  })
}

resource "aws_lambda_function" "inbound_email" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INBOX_TABLE         = local.inbox_table_name
      INBOX_MESSAGE_TABLE = local.message_table_name
    }
  }
}

/*resource "aws_lambda_permission" "allow_ses" {
  statement_id  = "AllowSESToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inbound_email.function_name
  principal     = "ses.amazonaws.com"
  source_arn    = aws_ses_receipt_rule.lambda_rule.arn
}*/
resource "aws_lambda_permission" "allow_ses" {
  statement_id  = "AllowSESToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inbound_email.function_name
  principal     = "ses.amazonaws.com"
  # precompute the rule ARN instead of referencing the rule resource
  # source_arn    = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${aws_ses_receipt_rule_set.main.rule_set_name}:receipt-rule/${local.lambda_name}"
  source_arn    = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/default-rule-set:receipt-rule/${local.lambda_name}"
}

/*resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = local.lambda_name
}*/


resource "aws_ses_receipt_rule" "lambda_rule" {
  name          = local.lambda_name
  rule_set_name = "default-rule-set" # aws_ses_receipt_rule_set.main.rule_set_name
  recipients    = [local.domain]
  enabled       = true
  scan_enabled  = false

  lambda_action {
    function_arn    = aws_lambda_function.inbound_email.arn
    invocation_type = "Event"
    position        = 1
  }
}
resource "aws_iam_role_policy_attachment" "codebuild_inbound_iam_policy_attach" {
  role       = module.buildpipeline.code_build_iam_role.name
  policy_arn = aws_iam_policy.code_pipeline_inbound_iam_policy.arn
}

resource "aws_iam_policy" "code_pipeline_inbound_iam_policy" {
  name = "schematical-com-v1-${var.env}-codepipeline-inbound-email"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {

          "Action" : [
            "lambda:UpdateFunctionCode"
          ],
          "Resource" : aws_lambda_function.inbound_email.arn,
          "Effect" : "Allow"
        }
      ]
    }
  )
}

/*resource "aws_ses_active_receipt_rule_set" "active" {
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
}*/

output "lambda_function_arn" {
  value = aws_lambda_function.inbound_email.arn
}

output "ses_domain_identity_arn" {
  value = aws_ses_domain_identity.domain.arn
}