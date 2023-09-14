## WORK IN PROGRESS


### How to add another host / ECS service to the ALB:

```
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.alb_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }


  condition {
    host_header {
      values = ["example.com"]
    }
  }
}

```
https://registry.terraform.io/providers/hashicorp/aws/3.46.0/docs/resources/lb_listener_rule