/*resource "aws_iam_user" "iam_user_upwork1" {
  name = "upwork1"
}

resource "aws_iam_access_key" "iam_user_access_key_joe" {
  user = aws_iam_user.iam_user_upwork1.name
}

resource "aws_iam_user_policy_attachment" "iam_user_joe_policy_attachment" {
  user       = aws_iam_user.iam_user_upwork1.name
  policy_arn = aws_iam_policy.upwork_iam_policy.arn
}*/
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
/*resource "local_file" "private_key" {
  content  = "${aws_iam_access_key.iam_user_access_key_joe.id}\n${aws_iam_access_key.iam_user_access_key_joe.secret}"
  filename = "creds.txt"
}*/
# terraform apply -target module.project_schematical_com.aws_iam_user.iam_user_upwork1 -target module.project_schematical_com.aws_iam_access_key.iam_user_access_key_joe  -target module.project_schematical_com.aws_iam_user_policy_attachment.iam_user_joe_policy_attachment  -target module.project_schematical_com.aws_iam_policy.upwork_iam_policy  -target module.project_schematical_com.local_file.private_key