

resource "aws_iam_policy" "policy_one" {
  name = "policy-618033"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_cognito_user_pool" "oc_demo" {
  # ... other configuration ...
  auto_verified_attributes   = [
     "email"
  ]
  # mfa_configuration          = "ON"
  sms_authentication_message = "Your code is {####}"
  schema {
    attribute_data_type = "String"
    name                = "email"
    required = true
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
  username     = "mlea+ocdemo@schematical.com"
  password = "oneTwo34$"
  attributes = {
    email          = "mlea+ocdemo@schematical.com"
  }
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


provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}

resource "aws_api_gateway_rest_api" "example" {
  name = "SchematicalMockApi"
}

resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "schematical"
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.demo.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
}

resource "aws_api_gateway_integration" "mock_integration" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  type                 = "MOCK"

/*  timeout_milliseconds = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }*/
  request_templates = {
    "application/xml" = jsonencode(
      {
        statusCode = 200
      }
    )
  }



}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = 200

  response_models = {
    "application/xml" = "Empty"
  }
}
resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/xml" = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<message>
    Schematical was here
</message>
EOF
  }
}

resource "aws_api_gateway_deployment" "example_deployment" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  depends_on  = [aws_api_gateway_integration.mock_integration]
  stage_name  = "prod"
}
resource "aws_iam_role" "test_role" {
  name = "MyAmazonAPIGatewayPushToCloudWatchLogs"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.policy_one.arn]
}

resource "aws_api_gateway_authorizer" "demo" {
  name                   = "demo"
  rest_api_id            = aws_api_gateway_rest_api.example.id
  # authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  # authorizer_credentials = aws_iam_role.invocation_role.arn
  type = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.oc_demo.arn]
}




output "api_endpoint" {
  value = "${aws_api_gateway_deployment.example_deployment.invoke_url}/schematical"
}
output "cw_role_arn" {
  value = "${aws_iam_role.test_role.arn}"
}
output "aws_cognito_user_pool_id" {
  value = aws_cognito_user_pool.oc_demo.id
}
output "aws_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}
