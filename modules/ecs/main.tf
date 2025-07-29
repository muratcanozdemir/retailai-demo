resource "aws_security_group" "ecs" {
  name        = "${var.cluster_name}-ecs-tasks"
  description = "ECS tasks for SonarQube"
  vpc_id      = var.vpc_id

  # NFS to EFS
  egress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.efs_security_group_id] # Passed in from EFS module
    description     = "NFS to EFS"
  }
  # Postgres to RDS
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_security_group_id]
    description     = "Postgres to RDS"
  }
  # Outbound to ALB
  egress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "ALB health checks, etc"
  }
  # Allow all outbound (for patching, external plugin installs, etc)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default outbound"
  }
  tags = { Name = "${var.cluster_name}-ecs-tasks" }
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "sonarqube"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "sonarqube"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
        }
      ]
      environment = concat([
        { name = "SONAR_JDBC_URL", value = "jdbc:postgresql://${var.db_endpoint}:5432/${var.db_name}" },
        { name = "SONAR_JDBC_USERNAME", value = var.db_user },
        # password fetched from secrets manager at runtime
        { name = "SONAR_JDBC_PASSWORD", valueFrom = var.db_secret_arn }
        # Optionally: add IAM_TOKEN env if using IAM auth
      ], var.extra_env)
      mountPoints = [
        {
          sourceVolume  = "sonarqube-data"
          containerPath = "/opt/sonarqube/data"
          readOnly      = false
        }
      ]
      readonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/sonarqube"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  volume {
    name = "sonarqube-data"
    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_arn
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "sonarqube" {
  name            = "sonarqube"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.sonarqube.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "sonarqube"
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  # Consider circuit breaker for enterprise workloads
}

data "aws_region" "current" {}
