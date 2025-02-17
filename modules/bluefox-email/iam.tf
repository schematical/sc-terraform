resource "aws_iam_user" "iam_user" {
  name = var.iam_username
  # path = "/system/"
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.iam_user.name
  policy_arn = aws_iam_policy.ses_policy.arn
}
resource "aws_iam_access_key" "iam_user_access_key" {
  user =  aws_iam_user.iam_user.name
}
resource "local_file" "access_key" {
  content  = "${aws_iam_access_key.iam_user_access_key.id}\n${aws_iam_access_key.iam_user_access_key.secret}"
  filename = "creds/${aws_iam_access_key.iam_user_access_key.user}-access-key.txt"
}
resource "aws_iam_policy" "ses_policy" {
    name = "${var.iam_username}-role"

    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ses:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }