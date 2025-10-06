# Terraform Outputs for EPL Live Infrastructure

# VPC Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "IDs of private subnets"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "IDs of public subnets"
}

# ECS Outputs
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Name of the ECS cluster"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "ARN of the ECS cluster"
}

output "producer_service_name" {
  value       = aws_ecs_service.producer.name
  description = "Name of the producer ECS service"
}

output "consumer_service_name" {
  value       = aws_ecs_service.consumer.name
  description = "Name of the consumer ECS service"
}

# Kafka on ECS Outputs
output "kafka_bootstrap_servers" {
  value       = "kafka.${var.project_name}.local:9092"
  description = "Kafka bootstrap servers endpoint"
}

output "kafka_service_name" {
  value       = aws_ecs_service.kafka.name
  description = "Name of the Kafka ECS service"
}

# Redis Outputs
output "redis_endpoint" {
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
  description = "Redis endpoint (host:port)"
}

output "redis_host" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "Redis host address"
}

output "redis_port" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
  description = "Redis port"
}

# Security Group Outputs
output "ecs_security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "Security group ID for ECS tasks"
}

output "kafka_security_group_id" {
  value       = aws_security_group.kafka.id
  description = "Security group ID for Kafka on ECS"
}

output "redis_security_group_id" {
  value       = aws_security_group.redis.id
  description = "Security group ID for Redis cluster"
}

output "efs_id" {
  value       = aws_efs_file_system.kafka.id
  description = "ID of the EFS file system for Kafka data"
}

# Useful Commands
output "useful_commands" {
  value = <<-EOT
    # View ECS service status
    aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.kafka.name} ${aws_ecs_service.producer.name} ${aws_ecs_service.consumer.name}

    # View ECS tasks
    aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name}

    # View producer logs
    aws logs tail ${aws_cloudwatch_log_group.producer.name} --follow

    # View consumer logs
    aws logs tail ${aws_cloudwatch_log_group.consumer.name} --follow

    # View Kafka logs
    aws logs tail ${aws_cloudwatch_log_group.kafka.name} --follow

    # Update Kafka service (force new deployment)
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.kafka.name} --force-new-deployment

    # Update producer service (force new deployment)
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.producer.name} --force-new-deployment

    # Update consumer service (force new deployment)
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.consumer.name} --force-new-deployment

    # Scale producer service
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.producer.name} --desired-count 2

    # Scale consumer service
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.consumer.name} --desired-count 2
  EOT
  description = "Useful AWS CLI commands for managing the infrastructure"
}

# Cost Estimation Output
output "estimated_monthly_cost" {
  value = <<-EOT
    Estimated Monthly Costs (USD):
    ==============================
    ECS Fargate (3 tasks):
      - Kafka (1 vCPU, 2GB):                ~$30
      - Producer (0.5 vCPU, 1GB):           ~$15
      - Consumer (0.5 vCPU, 1GB):           ~$15
    ElastiCache Redis (cache.t3.micro):     ~$12
    NAT Gateway (1 gateway):                ~$30
    EFS (minimal storage):                  ~$3
    Data Transfer & Logs:                   ~$5
    ==============================
    TOTAL:                                  ~$110/month

    💰 Cost Savings vs MSK: ~$100/month (48% reduction)

    Cost Optimization Tips:
    - Use Spot instances for ECS tasks (save 70%)
    - Reduce log retention period (currently 7 days)
    - Use S3 for long-term Kafka data storage
    - Schedule scaling to reduce off-peak usage
  EOT
  description = "Estimated monthly cost breakdown"
}
