
resource "aws_iam_policy" "upwork_iam_policy" {
  name = "upwork"

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
            "dynamodb:Query",
            "dynamodb:BatchGetItem"
          ],
          "Resource" :  aws_dynamodb_table.dynamodb_table_post.arn
        }

      ]
    }
  )
}
