# EFS for Kafka persistent storage
resource "aws_efs_file_system" "kafka" {
  creation_token = "${var.project_name}-kafka-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-kafka-efs"
  }
}

resource "aws_efs_mount_target" "kafka" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.kafka.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

# Security group for Kafka
resource "aws_security_group" "kafka" {
  name        = "${var.project_name}-kafka-sg"
  description = "Security group for Kafka running on ECS"
  vpc_id      = module.vpc.vpc_id

  # Kafka broker communication
  ingress {
    description     = "Kafka broker from ECS tasks"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Kafka inter-broker communication
  ingress {
    description = "Kafka inter-broker"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    self        = true
  }

  # ZooKeeper
  ingress {
    description = "ZooKeeper"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-kafka-sg"
  }
}

# Service Discovery namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Private DNS namespace for service discovery"
  vpc         = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-dns-namespace"
  }
}

# Service Discovery for Kafka
resource "aws_service_discovery_service" "kafka" {
  name = "kafka"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "${var.project_name}-kafka-discovery"
  }
}

# Kafka Task Definition
resource "aws_ecs_task_definition" "kafka" {
  family                   = "epl-kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.kafka_cpu
  memory                   = var.kafka_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  volume {
    name = "kafka-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.kafka.id
      transit_encryption = "ENABLED"
      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "kafka"
      image     = "bitnami/kafka:${var.kafka_version}"
      essential = true

      portMappings = [
        {
          containerPort = 9092
          protocol      = "tcp"
        },
        {
          containerPort = 9093
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "kafka-data"
          containerPath = "/bitnami/kafka"
          readOnly      = false
        }
      ]

      environment = [
        {
          name  = "KAFKA_CFG_NODE_ID"
          value = "1"
        },
        {
          name  = "KAFKA_CFG_PROCESS_ROLES"
          value = "controller,broker"
        },
        {
          name  = "KAFKA_CFG_LISTENERS"
          value = "PLAINTEXT://:9092,CONTROLLER://:9093"
        },
        {
          name  = "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP"
          value = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
        },
        {
          name  = "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS"
          value = "1@127.0.0.1:9093"
        },
        {
          name  = "KAFKA_CFG_CONTROLLER_LISTENER_NAMES"
          value = "CONTROLLER"
        },
        {
          name  = "KAFKA_CFG_INTER_BROKER_LISTENER_NAME"
          value = "PLAINTEXT"
        },
        {
          name  = "KAFKA_CFG_ADVERTISED_LISTENERS"
          value = "PLAINTEXT://kafka.${var.project_name}.local:9092"
        },
        {
          name  = "KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE"
          value = "true"
        },
        {
          name  = "KAFKA_CFG_LOG_RETENTION_HOURS"
          value = "168"
        },
        {
          name  = "KAFKA_CFG_LOG_SEGMENT_BYTES"
          value = "1073741824"
        },
        {
          name  = "KAFKA_CFG_LOG_RETENTION_CHECK_INTERVAL_MS"
          value = "300000"
        },
        {
          name  = "KAFKA_CFG_NUM_PARTITIONS"
          value = "3"
        },
        {
          name  = "KAFKA_CFG_DEFAULT_REPLICATION_FACTOR"
          value = "1"
        },
        {
          name  = "ALLOW_PLAINTEXT_LISTENER"
          value = "yes"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.kafka.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "kafka-broker-api-versions.sh --bootstrap-server localhost:9092 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-kafka"
  }
}

# Kafka ECS Service
resource "aws_ecs_service" "kafka" {
  name            = "epl-kafka-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.kafka.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.kafka.id, aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kafka.arn
  }

  deployment_configuration {
    maximum_percent         = 100
    minimum_healthy_percent = 0
  }

  tags = {
    Name = "${var.project_name}-kafka-service"
  }

  depends_on = [
    aws_efs_mount_target.kafka
  ]
}

# CloudWatch Log Group for Kafka
resource "aws_cloudwatch_log_group" "kafka" {
  name              = "/ecs/epl-kafka"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-kafka-logs"
  }
}

# Outputs
output "kafka_bootstrap_servers" {
  value       = "kafka.${var.project_name}.local:9092"
  description = "Kafka bootstrap servers endpoint"
}

output "kafka_service_name" {
  value       = aws_ecs_service.kafka.name
  description = "Name of the Kafka ECS service"
}
