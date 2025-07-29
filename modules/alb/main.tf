resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-alb-sg"
  description = "SG for internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Internal HTTPS access to ALB"
  }

  egress {
    from_port   = 443
    to_port     = 443
    description = "Some description"
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = { Name = "${var.alb_name}-alb-sg" }
}

resource "aws_lb" "this" {
  name                       = var.alb_name
  internal                   = true
  load_balancer_type         = "application"
  subnets                    = var.private_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = true
  drop_invalid_header_fields = true
  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "sonarqube-alb"
    enabled = true
  }

  tags = { Name = var.alb_name }
}

resource "aws_lb_target_group" "sonarqube" {
  name        = "${var.alb_name}-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # ECS on Fargate requires this

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = { Name = "${var.alb_name}-tg" }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port # 443
  protocol          = var.alb_protocol  # HTTPS
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
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