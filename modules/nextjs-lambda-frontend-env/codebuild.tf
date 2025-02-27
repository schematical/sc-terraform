
module "buildpipeline" {
  source = "../buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = var.service_name
  region = var.region
  env = var.env
  github_owner = var.github_owner
  github_project_name = var.github_project_name
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = var.source_buildspec_path
  codestar_connection_arn = var.codestar_connection_arn
  env_vars = merge(
    {
      ENV: var.env
      SERVICE_NAME: var.service_name
      NEXT_PUBLIC_SERVER_URL:  "https://${var.subdomain}.${var.hosted_zone_name}"
      // NEXT_PUBLIC_STRIPE_PUBLIC_KEY: var.secrets.drawnby_frontend_REACT_APP_STRIPE_PUBLIC_KEY
      // AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
      // AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
      S3_BUCKET: module.cloudfront.s3_bucket.bucket
      PUBLIC_ASSET_URL: "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}"
      # REPOSITORY_URI: aws_ecr_repository.ecr_repository.repository_url
    },
    var.extra_env_vars
  )

}
resource "aws_iam_policy" "codebuild_iam_policy" {
  name = "${var.service_name}-${var.env}-codebuild"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "LambdaDeploy",
          "Effect": "Allow",
          "Action": [
            "lambda:UpdateFunctionCode",
            "lambda:GetFunction",
            "lambda:UpdateFunctionConfiguration"
          ],
          "Resource": [
            module.lambda_service.lambda_function.arn
          ]
        },
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
            "${module.cloudfront.s3_bucket.arn}/**",
            "${module.cloudfront.s3_bucket.arn}"
          ]
        },
        /*{
          "Sid": "AllowDescribeRepoImage",
          "Effect": "Allow",
          "Action": [
            "ecr:*"
          ],
          "Resource": [
            aws_ecr_repository.ecr_repository.arn,
            "${aws_ecr_repository.ecr_repository.arn}:*"
          ]
        },*/
        {
          "Sid":"GetAuthorizationToken",
          "Effect":"Allow",
          "Action":[
            "ecr:GetAuthorizationToken"
          ],
          "Resource":"*"
        },
      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "codebuild_iam_policy_attach" {
  role = module.buildpipeline.code_build_iam_role.name
  policy_arn = aws_iam_policy.codebuild_iam_policy.arn
}