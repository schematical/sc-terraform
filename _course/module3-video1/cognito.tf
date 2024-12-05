resource "aws_cognito_user_pool" "oc_demo" {
  # ... other configuration ...

  # mfa_configuration          = "ON"
  sms_authentication_message = "Your code is {####}"
  schema {
    attribute_data_type = "String"
    name                = "email"
  }
/*  sms_configuration {
    external_id    = "example"
    sns_caller_arn = aws_iam_role.example.arn
    sns_region     = "us-east-1"
  }*/

/*  software_token_mfa_configuration {
    enabled = true
  }*/
  name = "oc-demo"
}
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "schematical2"
  user_pool_id = aws_cognito_user_pool.oc_demo.id
}
resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.oc_demo.id
  username     = "example"
  password = "oneTwo34$"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.oc_demo.id
  callback_urls                        = ["https://example.com"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
}