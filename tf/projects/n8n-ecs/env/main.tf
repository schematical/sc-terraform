data "aws_caller_identity" "current" {}
locals{
  container_port = 5678
  NEXT_PUBLIC_SERVER_URL = "https://${var.subdomain}.${var.hosted_zone_name}"
  PUBLIC_ASSET_URL = "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
}


resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ecs_iam_policy.arn
}
resource "aws_iam_policy" "ecs_iam_policy" {
  name = "n8n-schematical-com-v1-${var.env}-ecs"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect": "Allow",
          "Action": [
            "dsql:DbConnect",
            "dsql:DbConnectAdmin"
          ]
          "Resource": var.dsql_cluster_arn
        }
      ]
    }
  )
}

