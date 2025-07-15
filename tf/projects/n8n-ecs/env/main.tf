data "aws_caller_identity" "current" {}
locals{
  container_port = 3000
  NEXT_PUBLIC_SERVER_URL = "https://${var.subdomain}.${var.hosted_zone_name}"
  PUBLIC_ASSET_URL = "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
}

resource "aws_iam_policy" "ecs_iam_policy" {
  name = "n8n-schematical-com-v1-${var.env}-ecs"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        /* {
           "Sid" : "DynamoDB",
           "Effect" : "Allow",
           "Action" : [
             "dynamodb:Scan",
             "dynamodb:GetItem",
             "dynamodb:PutItem",
             "dynamodb:Query",
             "dynamodb:BatchGetItem"
           ],
           "Resource" : var.dynamodb_table_arns
         },
         {
           "Sid" : "s3",
           "Effect" : "Allow",
           "Action" : [
             "s3:PutObject",
             "s3:PutObjectAcl",
             "s3:DeleteObject"
           ],
           "Resource" : [
             "${module.cloudfront.s3_bucket.arn}/uploads/**"
           ]
         }*/
      ]
    }
  )
}

/*
resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role = module.nextjs_lambda.iam_role_name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
resource "aws_wafv2_web_acl_association" "wafv2_web_acl_association" {
  resource_arn = module.nextjs_lambda.api_gateway_stage_arn
  web_acl_arn  = var.waf_web_acl_arn
}*/
