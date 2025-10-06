# Variables for EPL Live Pipeline

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "epl-live"
}

variable "image_tag" {
  description = "Docker image tag for deployment"
  type        = string
  default     = "latest"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ECS Configuration
variable "producer_cpu" {
  description = "CPU units for producer task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "producer_memory" {
  description = "Memory for producer task in MB"
  type        = number
  default     = 1024
}

variable "consumer_cpu" {
  description = "CPU units for consumer task"
  type        = number
  default     = 512
}

variable "consumer_memory" {
  description = "Memory for consumer task in MB"
  type        = number
  default     = 1024
}

variable "producer_count" {
  description = "Number of producer tasks to run"
  type        = number
  default     = 1
}

variable "consumer_count" {
  description = "Number of consumer tasks to run"
  type        = number
  default     = 2
}

# Kafka ECS Configuration
variable "kafka_version" {
  description = "Kafka Docker image version"
  type        = string
  default     = "3.6.1"
}

variable "kafka_cpu" {
  description = "CPU units for Kafka task"
  type        = number
  default     = 1024
}

variable "kafka_memory" {
  description = "Memory for Kafka task in MB"
  type        = number
  default     = 2048
}

# Redis/ElastiCache Configuration
variable "redis_node_type" {
  description = "Node type for Redis"
  type        = string
  default     = "cache.t3.micro"
}

# Application Secrets
variable "football_api_key" {
  description = "Football API key"
  type        = string
  sensitive   = true
}

variable "convex_url" {
  description = "Convex deployment URL"
  type        = string
}

variable "convex_deploy_key" {
  description = "Convex deployment key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_mock_data" {
  description = "Enable mock data for testing"
  type        = bool
  default     = false
}
