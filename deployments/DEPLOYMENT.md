# Deployment Guide

This guide covers deploying the Live EPL pipeline to AWS.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Docker installed
- Terraform (optional, for IaC)
- Football API key from [Football-Data.org](https://www.football-data.org/client/register)

## Architecture Overview

```
Internet → ALB → ECS (Producer) → MSK (Kafka) → ECS (Consumer) → DynamoDB/S3
                                                                      ↓
                                                               Convex Functions
                                                                      ↓
                                                          Next.js Dashboard (Vercel/AWS)
```

## Step-by-Step Deployment

### 1. Setup AWS Infrastructure

#### Option A: Using Terraform (Recommended)

```bash
cd deployments/terraform
terraform init
terraform plan
terraform apply
```

#### Option B: Manual Setup

1. **Create VPC and Subnets**
   - VPC with CIDR 10.0.0.0/16
   - Private subnets in 2 AZs

2. **Create DynamoDB Table**
   - Table name: `epl-live-matches`
   - Primary key: `match_id` (String)
   - Billing mode: Pay per request

3. **Create S3 Bucket**
   - Bucket name: `epl-match-snapshots-{account-id}`
   - Enable versioning

4. **Create ECR Repositories**
   ```bash
   aws ecr create-repository --repository-name live-epl-producer
   aws ecr create-repository --repository-name live-epl-consumer
   ```

### 2. Setup AWS MSK (Managed Kafka)

1. Create MSK cluster:
   ```bash
   aws kafka create-cluster \
     --cluster-name live-epl-cluster \
     --broker-node-group-info file://msk-broker-config.json \
     --kafka-version "3.5.1" \
     --number-of-broker-nodes 3
   ```

2. Get bootstrap servers:
   ```bash
   aws kafka get-bootstrap-brokers --cluster-arn YOUR_CLUSTER_ARN
   ```

### 3. Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push producer
cd services/producer
docker build -t live-epl-producer .
docker tag live-epl-producer:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/live-epl-producer:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/live-epl-producer:latest

# Build and push consumer
cd ../consumer
docker build -t live-epl-consumer .
docker tag live-epl-consumer:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/live-epl-consumer:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/live-epl-consumer:latest
```

### 4. Setup IAM Roles

Create two IAM roles:

**ECS Task Execution Role** (for pulling images, logs):
- `AmazonECSTaskExecutionRolePolicy`
- `CloudWatchLogsFullAccess`

**ECS Task Role** (for application permissions):
- DynamoDB read/write permissions
- S3 read/write permissions
- MSK connect permissions

### 5. Store Secrets

```bash
# Store Football API key
aws secretsmanager create-secret \
  --name football-api-key \
  --secret-string "YOUR_API_KEY"
```

### 6. Deploy ECS Services

1. Update task definitions in `deployments/ecs-task-definitions/` with:
   - Your account ID
   - ECR image URIs
   - MSK bootstrap servers
   - IAM role ARNs

2. Register task definitions:
   ```bash
   aws ecs register-task-definition --cli-input-json file://deployments/ecs-task-definitions/producer-task.json
   aws ecs register-task-definition --cli-input-json file://deployments/ecs-task-definitions/consumer-task.json
   ```

3. Create ECS cluster:
   ```bash
   aws ecs create-cluster --cluster-name live-epl-cluster
   ```

4. Create services:
   ```bash
   aws ecs create-service \
     --cluster live-epl-cluster \
     --service-name producer \
     --task-definition epl-producer \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"

   aws ecs create-service \
     --cluster live-epl-cluster \
     --service-name consumer \
     --task-definition epl-consumer \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
   ```

### 7. Setup Convex

1. Install Convex CLI:
   ```bash
   npm install -g convex
   ```

2. Deploy Convex functions:
   ```bash
   cd frontend/convex-functions
   npm install
   npx convex dev  # or `npx convex deploy` for production
   ```

3. Copy the deployment URL

### 8. Setup Clerk Authentication

1. Create account at [Clerk.dev](https://clerk.dev)
2. Create new application
3. Copy API keys

### 9. Deploy Frontend

#### Option A: Vercel (Recommended)

1. Push code to GitHub
2. Import project in Vercel
3. Set environment variables:
   ```
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
   CLERK_SECRET_KEY=sk_...
   NEXT_PUBLIC_CONVEX_URL=https://...convex.cloud
   ```
4. Deploy

#### Option B: AWS Amplify

1. Connect GitHub repository
2. Set environment variables
3. Deploy

### 10. Update Consumer to Write to Convex

Modify `services/consumer/app/storage.py` to call Convex mutations:

```python
import aiohttp

async def write_to_convex(event: Dict[str, Any]):
    async with aiohttp.ClientSession() as session:
        url = f"{CONVEX_URL}/api/mutations/matches/upsertMatch"
        headers = {"Authorization": f"Bearer {CONVEX_API_KEY}"}
        await session.post(url, json=event, headers=headers)
```

## Monitoring

### CloudWatch Logs
- Producer logs: `/ecs/epl-producer`
- Consumer logs: `/ecs/epl-consumer`

### CloudWatch Metrics
- ECS task CPU/Memory
- MSK broker metrics
- DynamoDB read/write capacity

### Alarms (Recommended)
- ECS task failures
- Kafka consumer lag
- DynamoDB throttling

## Scaling

### Auto-scaling ECS Tasks
```bash
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/live-epl-cluster/consumer \
  --min-capacity 1 \
  --max-capacity 10
```

### MSK Scaling
- Monitor broker CPU/disk
- Add broker nodes as needed

## Cost Optimization

- Use Fargate Spot for non-critical tasks
- Enable DynamoDB auto-scaling
- Set S3 lifecycle policies for old snapshots
- Use MSK dev configuration for testing

## Troubleshooting

### Consumer not receiving messages
- Check security groups allow MSK access
- Verify bootstrap servers are correct
- Check consumer group status

### High latency
- Scale ECS tasks
- Increase MSK broker capacity
- Optimize DynamoDB indexes

### Producer errors
- Check API rate limits
- Verify API key in Secrets Manager
- Check CloudWatch logs
