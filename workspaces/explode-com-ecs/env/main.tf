data "aws_caller_identity" "current" {}
locals{
  container_port = 3000
  NEXT_PUBLIC_SERVER_URL = "https://${var.subdomain}.${var.hosted_zone_name}"
  PUBLIC_ASSET_URL = "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name = "schematical-com-v1-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
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
        }

      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
