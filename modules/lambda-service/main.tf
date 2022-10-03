resource "aws_iam_role" "service_lambda_iam_role" {
  name = join("-", [var.service_prefix, var.service_name, var.service_version, var.service_env, "lambda"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_security_group" "service_lambda_sg" {
  name        = join("-", [var.service_prefix, var.service_name, var.service_version, var.service_env, "lambda"])
  description =  join("-", [var.service_prefix, var.service_name, var.service_version, var.service_env, "lambda"])
  vpc_id      = var.vpc_id

  /*ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }*/

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Terraform = "true"
  }
}
resource "aws_lambda_function" "service_lambda_web"  {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = join("-", [var.service_prefix, var.service_name, var.service_version, var.service_env])
  role          = aws_iam_role.service_lambda_iam_role.arn
  handler       = "index.test"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "nodejs16.x"

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.service_lambda_sg.id]
  }

  environment {
    variables = {
      Terraform = "true"
    }
  }
}
resource "aws_api_gateway_resource" "aws_api_gateway_resource" {
  rest_api_id = var.api_gateway_id # aws_api_gateway_rest_api.MyDemoAPI.id
  parent_id   = var.api_gateway_parent_id # aws_api_gateway_rest_api.MyDemoAPI.root_resource_id
  path_part   = var.service_uri
}

