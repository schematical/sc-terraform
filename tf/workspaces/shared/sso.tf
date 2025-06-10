/*

data "aws_ssoadmin_instances" "example" {}

resource "aws_ssoadmin_permission_set" "example" {
  name         = "Example"
  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
}
module.shared_env.data.aws_ssoadmin_instances.example
module.shared_env.aws_acm_certificate.shared_acm_cert
module.shared_env.aws_ssoadmin_permission_set.example

*/
