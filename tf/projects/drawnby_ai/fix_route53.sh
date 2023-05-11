terraform apply -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-a \
  -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-ns \
  -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-mx \
  -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-soa \
  -target  module.project_drawnby_ai.aws_route53_record.drawnby-ai-cname-www \
  -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-cname-mc-1 \
  -target module.project_drawnby_ai.aws_route53_record.drawnby-ai-cname-mc-2