data "aws_caller_identity" "current" {}

resource "aws_acm_certificate" "cert" {
  count             = var.existing_cert_arn == "" ? 1 : 0
  domain_name       = var.acm_cert_domain_name
  validation_method = "DNS"

  tags = {
    Name = "${var.app_name}-cert"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.existing_cert_arn == "" ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = var.existing_cert_arn == "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  count             = var.existing_log_group_name == "" ? 1 : 0
  name              = var.existing_log_group_name == "" ? "/ecs/${var.app_name}" : var.existing_log_group_name
  retention_in_days = 30
}

resource "aws_security_group" "lb_sg" {
  count        = var.existing_lb_sg_id == "" ? 1 : 0
  name         = "${var.app_name}-lb-sg"
  description  = "Allow HTTP and HTTPS inbound traffic"
  vpc_id       = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  count        = var.existing_ecs_sg_id == "" ? 1 : 0
  name         = "${var.app_name}-ecs-sg"
  description  = "Allow inbound traffic from Load Balancer"
  vpc_id       = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "app_cluster" {
  count = var.existing_ecs_cluster_arn == "" ? 1 : 0
  name  = "${var.app_name}-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.existing_task_execution_role_arn == "" ? 1 : 0
  name  = "${var.app_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role" "ecs_task_role" {
  count = var.existing_task_role_arn == "" ? 1 : 0
  name  = "${var.app_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_ecs_task_definition" "app_task" {
  family                = "${var.app_name}-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = var.existing_task_execution_role_arn != "" ? var.existing_task_execution_role_arn : aws_iam_role.ecs_task_execution_role[0].arn
  task_role_arn         = var.existing_task_role_arn != "" ? var.existing_task_role_arn : aws_iam_role.ecs_task_role[0].arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repository_name != "" ? var.ecr_repository_name : var.app_name}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.existing_log_group_name != "" ? var.existing_log_group_name : aws_cloudwatch_log_group.ecs_log_group[0].name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.app_name
        }
      }
    }
  ])

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-service"
  cluster         = var.existing_ecs_cluster_arn != "" ? var.existing_ecs_cluster_arn : aws_ecs_cluster.app_cluster[0].id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.app_subnets # Private subnets for ECS tasks
    security_groups = [var.existing_ecs_sg_id != "" ? var.existing_ecs_sg_id : aws_security_group.ecs_sg[0].id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = var.app_name
    container_port   = 5000
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [
    aws_lb_listener.http_listener,
    aws_lb_listener.https_listener,
  ]
}

resource "aws_lb" "app_lb" {
  name               = "${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_lb_sg_id != "" ? var.existing_lb_sg_id : aws_security_group.lb_sg[0].id]
  subnets            = var.lb_public_subnets # Public subnets for the load balancer
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.app_name}-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_config["path"]
    interval            = var.health_check_config["interval"]
    timeout             = var.health_check_config["timeout"]
    healthy_threshold   = var.health_check_config["healthy_threshold"]
    unhealthy_threshold = var.health_check_config["unhealthy_threshold"]
    matcher             = var.health_check_config["matcher"]
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.existing_cert_arn != "" ? var.existing_cert_arn : aws_acm_certificate.cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_route53_record" "app_record" {
  zone_id = var.route53_zone_id
  name    = var.dns_record_name
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}