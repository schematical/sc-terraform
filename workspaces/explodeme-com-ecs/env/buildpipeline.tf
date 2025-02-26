resource "aws_codestarconnections_connection" "codestarconnections_connection" {
  name          = "github-connection"
  provider_type = "GitHub"
}

module "buildpipeline" {
  source                              = "../../../modules/buildpipeline"
  # "github.com/explode/sc-terraform/modules/buildpipeline"
  service_name                        = "explodeme-com"
  region                              = var.region
  env                                 = var.env
  github_owner                        = "schematical"
  github_project_name                 = "explodeme-com"
  github_source_branch                = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id                              = module.vpc.vpc_id
  private_subnet_mappings             = module.vpc.private_subnet_mappings
  source_buildspec_path               = "www/buildspec.yml"
  ecs_deploy_cluster_name             = aws_ecs_cluster.ecs_cluster.id
  ecs_deploy_service_name             = module.env_explode_com_ecs_service.ecs_service_name
  env_vars                            = {

    ENV : var.env
    SERVICE_NAME : var.service_name
    NEXT_PUBLIC_SERVER_URL : local.NEXT_PUBLIC_SERVER_URL
    /*AUTH_CLIENT_ID : var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID : var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID*/
    S3_BUCKET : module.cloudfront.s3_bucket.bucket
    PUBLIC_ASSET_URL : local.PUBLIC_ASSET_URL
  }
  codestar_connection_arn = aws_codestarconnections_connection.codestarconnections_connection.arn
}


resource "aws_iam_policy" "codebuild_iam_policy" {
  name = "explodeme-com-v1-${var.env}-codebuild"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [

        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
            "s3:PutObjectAcl",
            "s3:*"
          ]
          Resource = [
            "${module.cloudfront.s3_bucket.arn}*",
            "${module.cloudfront.s3_bucket.arn}"
          ]
        }

      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "codebuild_iam_policy_attach" {
  role       = module.buildpipeline.code_build_iam_role.name
  policy_arn = aws_iam_policy.codebuild_iam_policy.arn
}

resource "aws_iam_policy" "code_pipeline_iam_policy" {
  name = "explodeme-com-v1-${var.env}-codepipeline"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {

          "Action" : [
            "iam:PassRole"
          ],
          "Resource" : "*",
          "Effect" : "Allow",
          "Condition" : {
            "StringEqualsIfExists" : {
              "iam:PassedToService" : [
                "cloudformation.amazonaws.com",
                "elasticbeanstalk.amazonaws.com",
                "ec2.amazonaws.com",
                "ecs-tasks.amazonaws.com"
              ]
            }
          }
        },
        {
          "Action" : [
            "codecommit:CancelUploadArchive",
            "codecommit:GetBranch",
            "codecommit:GetCommit",
            "codecommit:GetUploadArchiveStatus",
            "codecommit:UploadArchive"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplication",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "codestar-connections:UseConnection"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [

            "autoscaling:*",
            "cloudwatch:*",
            "ecs:*"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "cloudformation:CreateStack",
            "cloudformation:DeleteStack",
            "cloudformation:DescribeStacks",
            "cloudformation:UpdateStack",
            "cloudformation:CreateChangeSet",
            "cloudformation:DeleteChangeSet",
            "cloudformation:DescribeChangeSet",
            "cloudformation:ExecuteChangeSet",
            "cloudformation:SetStackPolicy",
            "cloudformation:ValidateTemplate"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },

        {
          "Action" : [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },

        {
          "Effect" : "Allow",
          "Action" : [
            "cloudformation:ValidateTemplate"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:DescribeImages"
          ],
          "Resource" : "*"
        }


      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "code_pipeline_iam_policy_attach" {
  role       = module.buildpipeline.code_pipeline_service_role.name
  policy_arn = aws_iam_policy.code_pipeline_iam_policy.arn
}
