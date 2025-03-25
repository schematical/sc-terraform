resource "aws_iam_user" "iam_user" {
  for_each = toset(var.users)/*{
    for index, user in var.users:
    user.username => username
  }*/
  name = each.value
  # path = "/system/"
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  for_each = aws_iam_user.iam_user
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_access_key" "iam_user_access_key" {
  for_each = aws_iam_user.iam_user
  user =  each.value.name
}
resource "local_file" "access_key" {
  for_each = aws_iam_access_key.iam_user_access_key
  content  = "${each.value.id}\n${each.value.secret}"
  filename = "creds/${each.value.user}-access-key.txt"
}
resource "aws_iam_user_login_profile" "iam_user_login_profile" {
  for_each = aws_iam_user.iam_user
  user =  each.value.name
}
resource "local_file" "login" {
  for_each = aws_iam_user_login_profile.iam_user_login_profile
  content  = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console\n${each.value.user}\n${each.value.password}"
  filename = "creds/${each.value.user}-login.txt"
}