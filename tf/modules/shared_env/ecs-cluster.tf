resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.env}-v1"

  /*setting {
    name  = "containerInsights"
    value = "enabled"
  }*/
}