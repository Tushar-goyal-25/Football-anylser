# ECR Repositories for Docker Images

resource "aws_ecr_repository" "producer" {
  name                 = "epl-producer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-producer"
  }
}

resource "aws_ecr_repository" "consumer" {
  name                 = "epl-consumer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-consumer"
  }
}

# Lifecycle policy to clean up old images
resource "aws_ecr_lifecycle_policy" "producer" {
  repository = aws_ecr_repository.producer.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "consumer" {
  repository = aws_ecr_repository.consumer.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Output ECR URLs
output "ecr_producer_url" {
  value = aws_ecr_repository.producer.repository_url
}

output "ecr_consumer_url" {
  value = aws_ecr_repository.consumer.repository_url
}
