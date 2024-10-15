
data "aws_ssoadmin_instances" "example" {}

resource "aws_ssoadmin_permission_set" "example" {
  name         = "Example"
  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
}