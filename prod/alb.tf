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



resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.frontend.arn

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


resource "aws_lb_listener_certificate" "api" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.backend.arn
}

resource "aws_lb_listener_certificate" "backend_scheduling" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.backend_scheduling.arn
}

locals {
  main_domain = "optimate.online"
}

resource "aws_acm_certificate" "frontend" {
  domain_name       = local.main_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${local.main_domain}"
  ]

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "backend" {
  domain_name       = "api.${local.main_domain}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.api.${local.main_domain}"
  ]

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "backend_scheduling" {
  domain_name       = "${var.env}-backend-scheduling.${local.main_domain}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.env}-backend-scheduling.${local.main_domain}"
  ]

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_acm_certificate" "static" {
#   domain_name       = "start.${local.main_domain}"
#   validation_method = "DNS"

#   subject_alternative_names = [
#     "*.start.${local.main_domain}"
#   ]

#   tags = {
#     Environment = var.env
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }



resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["*.${local.main_domain}"]
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
      values = ["*.api.${local.main_domain}", "api.${local.main_domain}"]
    }
  }

  # Need to be ignored because target group`s weight changed every deploy by CI/CD pipeline
  # In case of first deploy comment it and after deploy uncomment
  lifecycle {
    ignore_changes = [action]
  }
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
      values = ["*.${var.env}-backend-scheduling.${local.main_domain}", "${var.env}-backend-scheduling.${local.main_domain}"]
    }
  }
}


# resource "aws_lb_listener_rule" "static" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 98

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.static.arn
#   }

#   condition {
#     host_header {
#       values = ["*.start.${local.main_domain}", "start.${local.main_domain}"]
#     }
#   }
# }
