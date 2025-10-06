# CloudWatch Log Groups for ECS Services

# Producer Log Group
resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/epl-producer"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-producer-logs"
  }
}

# Consumer Log Group
resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/ecs/epl-consumer"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-consumer-logs"
  }
}

# CloudWatch Alarms for Producer Service

# Producer CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "producer_cpu_high" {
  alarm_name          = "${var.project_name}-producer-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when producer CPU exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.producer.name
  }

  tags = {
    Name = "${var.project_name}-producer-cpu-alarm"
  }
}

# Producer Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "producer_memory_high" {
  alarm_name          = "${var.project_name}-producer-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when producer memory exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.producer.name
  }

  tags = {
    Name = "${var.project_name}-producer-memory-alarm"
  }
}

# CloudWatch Alarms for Consumer Service

# Consumer CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "consumer_cpu_high" {
  alarm_name          = "${var.project_name}-consumer-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when consumer CPU exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.consumer.name
  }

  tags = {
    Name = "${var.project_name}-consumer-cpu-alarm"
  }
}

# Consumer Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "consumer_memory_high" {
  alarm_name          = "${var.project_name}-consumer-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when consumer memory exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.consumer.name
  }

  tags = {
    Name = "${var.project_name}-consumer-memory-alarm"
  }
}

# Kafka ECS Service Alarms

# Kafka CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "kafka_cpu_high" {
  alarm_name          = "${var.project_name}-kafka-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Kafka CPU exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.kafka.name
  }

  tags = {
    Name = "${var.project_name}-kafka-cpu-alarm"
  }
}

# Kafka Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "kafka_memory_high" {
  alarm_name          = "${var.project_name}-kafka-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Kafka memory exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.kafka.name
  }

  tags = {
    Name = "${var.project_name}-kafka-memory-alarm"
  }
}

# ElastiCache Redis Alarms

# Redis CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alert when Redis CPU exceeds 75%"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }

  tags = {
    Name = "${var.project_name}-redis-cpu-alarm"
  }
}

# Redis Memory Usage
resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  alarm_name          = "${var.project_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Redis memory usage exceeds 80%"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }

  tags = {
    Name = "${var.project_name}-redis-memory-alarm"
  }
}

# Outputs for CloudWatch Log Groups
output "producer_log_group_name" {
  value       = aws_cloudwatch_log_group.producer.name
  description = "CloudWatch log group name for producer"
}

output "consumer_log_group_name" {
  value       = aws_cloudwatch_log_group.consumer.name
  description = "CloudWatch log group name for consumer"
}
