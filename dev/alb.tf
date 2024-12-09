resource "aws_lb" "main" {
  name               = "${var.env}-${data.terraform_remote_state.networking.outputs.alb_main_name}"
  internal           = false
  load_balancer_type = "application"

  security_groups = [data.terraform_remote_state.networking.outputs.alb_main_sg_id]
  subnets         = data.terraform_remote_state.networking.outputs.public_subnets
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.env}-frontend"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.env}-backend"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "backend_blue" {
  name        = "${var.env}-backend-blue"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}


resource "aws_lb_target_group" "backend_scheduling" {
  name        = "${var.env}-backend-scheduling"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}

# resource "aws_lb_target_group" "static" {
#   name        = "${var.env}-static"
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "instance"
#   vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
# }



resource "aws_route53_record" "backend" {
  name    = "${var.env}-${data.terraform_remote_state.networking.outputs.alb_main_name}"
  type    = "A"
  zone_id = module.route53_zone.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backend_scheduling" {
  name    = "${var.env}-backend-scheduling"
  type    = "A"
  zone_id = module.route53_zone.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "frontend" {
  name    = "frontend"
  type    = "A"
  zone_id = module.route53_zone.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}



resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.route53_zone.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.frontend.fqdn]
    }
  }
}



resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.backend.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.backend_blue.arn
        weight = 0
      }
    }
  }

  condition {
    host_header {
      values = [aws_route53_record.backend.fqdn]
    }
  }

  # lifecycle {
  #   ignore_changes = [ action ]
  # }
}



resource "aws_lb_listener_rule" "backend_scheduling" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_scheduling.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.backend_scheduling.fqdn]
    }
  }
}
