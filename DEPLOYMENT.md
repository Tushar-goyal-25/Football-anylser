# EPL Live - AWS Deployment Guide

This guide walks you through deploying the EPL Live pipeline to AWS using Terraform and GitHub Actions CI/CD.

## Architecture Overview

- **AWS ECS (Fargate)**: Runs Kafka, producer & consumer containers
- **Kafka on ECS**: Self-hosted Kafka using Bitnami image (saves ~$100/month vs MSK)
- **AWS EFS**: Persistent storage for Kafka data
- **AWS ElastiCache**: Redis for caching
- **AWS ECR**: Docker image registry
- **AWS Secrets Manager**: Secure credential storage
- **GitHub Actions**: CI/CD pipeline

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** with the code
3. **Tools Installed**:
   - AWS CLI (`brew install awscli`)
   - Terraform (`brew install terraform`)
   - Docker

## Step 1: AWS Setup

### 1.1 Create IAM User for CI/CD

```bash
# Create IAM user
aws iam create-user --user-name epl-live-cicd

# Attach required policies
aws iam attach-user-policy --user-name epl-live-cicd --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
aws iam attach-user-policy --user-name epl-live-cicd --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
aws iam attach-user-policy --user-name epl-live-cicd --policy-arn arn:aws:iam::aws:policy/ElastiCacheFullAccess
aws iam attach-user-policy --user-name epl-live-cicd --policy-arn arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess
aws iam attach-user-policy --user-name epl-live-cicd --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Create access keys
aws iam create-access-key --user-name epl-live-cicd
```

Save the `AccessKeyId` and `SecretAccessKey` - you'll need them for GitHub Secrets.

### 1.2 Create S3 Bucket for Terraform State

```bash
aws s3api create-bucket \
  --bucket epl-live-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket epl-live-terraform-state \
  --versioning-configuration Status=Enabled
```

## Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | From Step 1.1 | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | From Step 1.1 | AWS IAM secret key |
| `TF_VAR_football_api_key` | Your API key | Football-Data.org API key |
| `TF_VAR_convex_url` | Your Convex URL | Convex deployment URL |
| `TF_VAR_convex_deploy_key` | Your Convex key | Convex deployment key (optional) |

## Step 3: Initial Terraform Setup

### 3.1 Create ECR Repositories First

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Create only ECR repositories initially
terraform apply -target=aws_ecr_repository.producer -target=aws_ecr_repository.consumer
```

### 3.2 Build and Push Initial Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push producer
docker build -t <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/epl-producer:latest -f services/producer/Dockerfile services/producer
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/epl-producer:latest

# Build and push consumer
docker build -t <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/epl-consumer:latest -f services/consumer/Dockerfile services/consumer
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/epl-consumer:latest
```

## Step 4: Deploy Full Infrastructure

### 4.1 Create terraform.tfvars

```bash
cd infra/terraform
cat > terraform.tfvars <<EOF
aws_region          = "us-east-1"
environment         = "production"
project_name        = "epl-live"
football_api_key    = "your-api-key-here"
convex_url          = "your-convex-url-here"
convex_deploy_key   = ""
enable_mock_data    = false
EOF
```

### 4.2 Apply Terraform

```bash
# Plan
terraform plan

# Apply
terraform apply
```

This will create:
- VPC with public/private subnets
- EFS for Kafka persistent storage
- Kafka on ECS (Fargate) with service discovery
- ElastiCache (Redis) cluster
- ECS cluster, task definitions, and services (Kafka, producer, consumer)
- Security groups and IAM roles
- CloudWatch log groups and alarms

## Step 5: Verify Deployment

```bash
# Check ECS services
aws ecs list-services --cluster epl-live-cluster

# Check task status
aws ecs list-tasks --cluster epl-live-cluster

# View logs
aws logs tail /ecs/epl-kafka --follow
aws logs tail /ecs/epl-producer --follow
aws logs tail /ecs/epl-consumer --follow
```

## Step 6: Enable CI/CD

Once infrastructure is deployed, every push to `main` branch will:

1. ✅ Run tests and linting
2. ✅ Build Docker images
3. ✅ Push to ECR
4. ✅ Deploy to ECS automatically

## Cost Estimation

| Service | Instance | Monthly Cost (USD) |
|---------|----------|-------------------|
| **ECS Fargate** | | |
| ├─ Kafka (1 vCPU, 2GB) | 1 task | ~$30 |
| ├─ Producer (0.5 vCPU, 1GB) | 1 task | ~$15 |
| └─ Consumer (0.5 vCPU, 1GB) | 1 task | ~$15 |
| **ElastiCache Redis** | cache.t3.micro | ~$12 |
| **NAT Gateway** | 1 gateway | ~$30 |
| **EFS** | Minimal storage | ~$3 |
| **Data Transfer & Logs** | | ~$5 |
| **Total** | | **~$110/month** |

💰 **Cost Savings**: ~$100/month (48% reduction) vs AWS MSK

### Cost Optimization Options:

1. ✅ **Kafka on ECS instead of MSK**: Already implemented, saving ~$100/month
2. ✅ **Single NAT Gateway**: Already implemented
3. **Use Spot instances**: Save ~70% on ECS costs
4. **Scale down non-production hours**: Use scheduled scaling
5. **Reduce log retention**: Currently 7 days, can reduce to 3 days

## Monitoring

- **CloudWatch Dashboards**: Auto-created for ECS services (Kafka, Producer, Consumer), Redis
- **CloudWatch Alarms**: CPU and memory alerts for all services
- **Logs**: Available in CloudWatch Logs
  - `/ecs/epl-kafka` - Kafka broker logs
  - `/ecs/epl-producer` - Producer logs
  - `/ecs/epl-consumer` - Consumer logs
- **Metrics**: CPU, Memory, Network for all services

## Troubleshooting

### ECS Tasks Not Starting
```bash
# Check task events
aws ecs describe-tasks --cluster epl-live-cluster --tasks <task-id>
```

### Kafka Connection Issues
```bash
# Get bootstrap servers
terraform output kafka_bootstrap_servers
# Should output: kafka.epl-live.local:9092

# Check Kafka service health
aws ecs describe-services --cluster epl-live-cluster --services epl-kafka-service

# Check Kafka logs
aws logs tail /ecs/epl-kafka --follow

# Verify service discovery
aws servicediscovery list-services --filters Name=NAMESPACE_ID,Values=<namespace-id>
```

### Redis Connection Issues
```bash
# Get Redis endpoint
terraform output redis_endpoint
```

## Rollback

```bash
# Rollback to previous deployment
aws ecs update-service --cluster epl-live-cluster --service epl-producer-service --task-definition epl-producer:<previous-revision>
```

## Cleanup

```bash
# Destroy all resources
cd infra/terraform
terraform destroy

# Delete S3 bucket
aws s3 rb s3://epl-live-terraform-state --force
```

## Next Steps

1. ✅ CloudWatch alarms - Already configured for all services
2. ✅ Auto-scaling policies - Already configured for producer/consumer
3. **Set up EFS backups** - Enable AWS Backup for Kafka data
4. **Implement blue-green deployments** - Use ECS deployment circuit breaker (already enabled)
5. **Add custom domain** - Set up Route53 for custom domain

## Support

For issues, check:
- GitHub Actions logs
- CloudWatch Logs
- AWS ECS console
