resource "aws_iam_user" "iam_user" {

  name = "${var.service_name}-${var.env}-ide"
  # path = "/system/"
}


resource "aws_iam_access_key" "iam_user_access_key" {
  user = aws_iam_user.iam_user.name
}
resource "local_file" "access_key" {
  content  = "${aws_iam_access_key.iam_user_access_key.id}\n${aws_iam_access_key.iam_user_access_key.secret}"
  filename = "creds/${aws_iam_user.iam_user.name}-access-key.txt"
}

resource "aws_iam_user_policy_attachment" "ide-user-policy-attach" {

  user       = aws_iam_user.iam_user.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}