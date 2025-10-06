# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# Producer Task Definition
resource "aws_ecs_task_definition" "producer" {
  family                   = "epl-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = "${aws_ecr_repository.producer.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.producer.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = "kafka.${var.project_name}.local:9092"
        },
        {
          name  = "KAFKA_TOPIC"
          value = "epl.matches"
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
        },
        {
          name  = "ENABLE_MOCK_DATA"
          value = tostring(var.enable_mock_data)
        }
      ]

      secrets = [
        {
          name      = "FOOTBALL_API_KEY"
          valueFrom = aws_secretsmanager_secret.football_api_key.arn
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "python -c 'import sys; sys.exit(0)'"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-producer"
  }
}

# Consumer Task Definition
resource "aws_ecs_task_definition" "consumer" {
  family                   = "epl-consumer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "consumer"
      image     = "${aws_ecr_repository.consumer.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.consumer.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = "kafka.${var.project_name}.local:9092"
        },
        {
          name  = "KAFKA_TOPIC"
          value = "epl.matches"
        },
        {
          name  = "KAFKA_GROUP_ID"
          value = "epl-consumer-group"
        },
        {
          name  = "CONVEX_URL"
          value = var.convex_url
        }
      ]

      secrets = concat(
        [
          {
            name      = "CONVEX_URL"
            valueFrom = aws_secretsmanager_secret.convex_url.arn
          }
        ],
        var.convex_deploy_key != "" ? [
          {
            name      = "CONVEX_DEPLOY_KEY"
            valueFrom = aws_secretsmanager_secret.convex_deploy_key[0].arn
          }
        ] : []
      )

      healthCheck = {
        command     = ["CMD-SHELL", "python -c 'import sys; sys.exit(0)'"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-consumer"
  }
}

# Producer ECS Service
resource "aws_ecs_service" "producer" {
  name            = "epl-producer-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-producer-service"
  }

  depends_on = [
    aws_ecs_service.kafka,
    aws_elasticache_cluster.redis
  ]
}

# Consumer ECS Service
resource "aws_ecs_service" "consumer" {
  name            = "epl-consumer-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-consumer-service"
  }

  depends_on = [
    aws_ecs_service.kafka
  ]
}

# Auto Scaling for Producer
resource "aws_appautoscaling_target" "producer" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.producer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "producer_cpu" {
  name               = "epl-producer-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.producer.resource_id
  scalable_dimension = aws_appautoscaling_target.producer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.producer.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling for Consumer
resource "aws_appautoscaling_target" "consumer" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.consumer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "consumer_cpu" {
  name               = "epl-consumer-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.consumer.resource_id
  scalable_dimension = aws_appautoscaling_target.consumer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.consumer.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
