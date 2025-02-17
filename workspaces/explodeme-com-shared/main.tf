locals {
  domain_name = "splittestgpt.com"
}
resource "aws_iam_role" "ecs_task_execution_iam_role" {
  name = "ECSTaskExecutionIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })


}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_iam_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_iam_role.name
}
resource "aws_iam_role" "anywhere_iam_role" {
  name = "ECSAnywhereIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

/*  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]*/
}
resource "aws_iam_role_policy_attachment" "anywhere_iam_role_policy_attachment_1" {
  policy_arn =  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ecs_task_execution_iam_role.name
}
resource "aws_iam_role_policy_attachment" "anywhere_iam_role_policy_attachment_2" {
  policy_arn =  "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs_task_execution_iam_role.name
}

resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "explodeme-com-codebuild-v1"
}

