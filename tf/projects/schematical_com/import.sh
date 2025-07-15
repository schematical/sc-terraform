# terraform import module.project_schematical_com.module.nextjs_lambda_frontend_base.aws_api_gateway_domain_name.api_gateway_domain_name schematical.com

terraform import module.project_schematical_com.module.prod_env_schematical_com.module.cloudfront.aws_s3_bucket.bucket schematical-com-prod-us-east-1-cloudfront

terraform import module.project_schematical_com.module.prod_env_schematical_com.module.cloudfront.aws_s3_bucket.bucket schematical-com-prod-us-east-1-cloudfront


terraform import module.project_sc_diagrams_com.module.dev_env_diagrams_com.module.nextjs_lambda.module.cloudfront.aws_s3_bucket.bucket sc-diagrams-dev-us-east-1-cloudfront

terraform import module.project_schematical_com.aws_lb_listener_rule.aws_lb_listener_rule_https arn:aws:elasticloadbalancing:us-east-1:368590945923:listener-rule/app/shared-v1-prod-alb/efe1dc59018d2443/b1e6b0e2b954ca85/58d4feb934580160
terraform import module.project_schematical_com.aws_lb_listener_rule.aws_lb_listener_rule_http arn:aws:elasticloadbalancing:us-east-1:368590945923:listener-rule/app/shared-v1-prod-alb/efe1dc59018d2443/b340a64d48763c14/a9fe89542154296c