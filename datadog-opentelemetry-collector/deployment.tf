data "aws_region" "current" {}
locals {
  collector_deployment_name       = "otel-collector"
  collector_otlp_port             = 4317
  collector_health_check_port     = 13133
  collector_health_check_endpoint = "/"
}

resource "aws_ecs_cluster" "otel" {
  name = var.name
}

resource "aws_security_group" "otel_collector" {
  name   = local.collector_deployment_name
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = local.collector_otlp_port
    to_port     = local.collector_otlp_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
    description = "Allow VPC traffic on OTLP port"
  }
  ingress {
    from_port   = local.collector_health_check_port
    to_port     = local.collector_health_check_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
    description = "Allow VPC traffic on OTLP port"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic by default"
  }
}
resource "aws_ecs_task_definition" "otel_collector" {
  family                   = local.collector_deployment_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name       = local.collector_deployment_name
      image      = "otel/opentelemetry-collector-contrib:0.127.0"
      essential  = true
      entryPoint = ["/otelcol-contrib"]
      command    = ["--config=env:OTEL_CONFIG"]
      portMappings = [
        {
          containerPort = local.collector_otlp_port
          hostPort      = local.collector_otlp_port
          protocol      = "tcp"
        },
        {
          containerPort = local.collector_health_check_port
          hostPort      = local.collector_health_check_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "OTEL_CONFIG"
          value = file("${path.module}/collector-config.yaml")
        }
      ]
      secrets = [
        {
          name      = "DATADOG_API_KEY"
          valueFrom = data.aws_secretsmanager_secret.datadog_api_key.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = local.collector_deployment_name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "otel_collector" {
  name            = local.collector_deployment_name
  cluster         = aws_ecs_cluster.otel.id
  task_definition = aws_ecs_task_definition.otel_collector.arn
  desired_count   = var.otel_workers_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.otel_collector.id]
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.otlp.arn
    container_name   = local.collector_deployment_name
    container_port   = local.collector_otlp_port
  }
}

resource "aws_alb_target_group" "otlp" {
  name        = "${local.collector_deployment_name}-otlp"
  port        = local.collector_otlp_port
  target_type = "ip"
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path = local.collector_health_check_endpoint
    port = local.collector_health_check_port
  }
}
