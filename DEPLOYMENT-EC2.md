# EPL Live - EC2 Single Instance Deployment

Deploy the entire EPL Live pipeline on a single AWS EC2 instance using Docker Compose.

## 💰 Cost Comparison

| Option | Monthly Cost | Free Tier |
|--------|--------------|-----------|
| **t3.micro** | $7/month | ✅ **FREE for 12 months** |
| **t3.small** (recommended) | $15/month | ❌ Not free |
| **Previous ECS/Fargate setup** | $110/month | ❌ Not free |

**💡 Savings: ~$103/month (94% reduction) vs ECS Fargate deployment**

---

## Architecture

**All services run on a single EC2 instance:**
```
EC2 Instance (t3.micro or t3.small)
├─ Docker & Docker Compose
├─ Kafka + ZooKeeper (in containers)
├─ Redis (in container)
├─ Producer (in container)
└─ Consumer (in container)
```

**No separate managed services needed!**

---

## Prerequisites

1. **AWS Account** (new accounts get 12 months free tier)
2. **AWS CLI** installed (`brew install awscli`)
3. **Terraform** installed (`brew install terraform`)
4. **SSH Key Pair** in AWS

---

## Step 1: Create SSH Key Pair (if you don't have one)

```bash
# Create key pair in AWS
aws ec2 create-key-pair \
  --key-name epl-live-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/epl-live-key.pem

# Set permissions
chmod 400 ~/.ssh/epl-live-key.pem
```

Or use AWS Console: EC2 → Key Pairs → Create Key Pair

---

## Step 2: Deploy Infrastructure with Terraform

```bash
cd infra/terraform-ec2

# Initialize Terraform
terraform init

# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
aws_region          = "us-east-1"
environment         = "production"
project_name        = "epl-live"
instance_type       = "t3.small"  # or "t3.micro" for free tier
ssh_key_name        = "epl-live-key"  # Your SSH key name
football_api_key    = "your-football-api-key-here"
convex_url          = "your-convex-url-here"
convex_deploy_key   = ""
enable_mock_data    = false
allowed_ssh_cidr    = ["YOUR_IP/32"]  # Replace with your IP for security
EOF

# Review the plan
terraform plan

# Deploy!
terraform apply
```

**Note the output:** Terraform will show you the SSH command and instance IP.

---

## Step 3: Copy Your Code to the Instance

```bash
# Get the instance IP from Terraform output
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Copy your services to the instance
scp -i ~/.ssh/epl-live-key.pem -r ../../services/producer ec2-user@$INSTANCE_IP:/opt/epl-live/
scp -i ~/.ssh/epl-live-key.pem -r ../../services/consumer ec2-user@$INSTANCE_IP:/opt/epl-live/

# Or use rsync (faster for updates)
rsync -avz -e "ssh -i ~/.ssh/epl-live-key.pem" \
  ../../services/ \
  ec2-user@$INSTANCE_IP:/opt/epl-live/
```

---

## Step 4: Start the Services

```bash
# SSH into the instance
ssh -i ~/.ssh/epl-live-key.pem ec2-user@$INSTANCE_IP

# Navigate to application directory
cd /opt/epl-live

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

**Expected output:**
```
NAME              STATUS          PORTS
epl-kafka         Up (healthy)    9092
epl-zookeeper     Up (healthy)    2181
epl-redis         Up (healthy)    6379
epl-producer      Up
epl-consumer      Up
```

---

## Step 5: Verify Deployment

```bash
# Check Kafka topics
docker exec epl-kafka kafka-topics --bootstrap-server localhost:9092 --list

# Check Redis
docker exec -it epl-redis redis-cli ping
# Should return: PONG

# View producer logs
docker-compose logs -f producer

# View consumer logs
docker-compose logs -f consumer

# Check resource usage
docker stats
```

---

## Useful Commands

### Managing Services

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f producer
docker-compose logs -f consumer
docker-compose logs -f kafka

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart producer

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v

# Update code and restart
docker-compose down
docker-compose build
docker-compose up -d
```

### Monitoring

```bash
# Check container status
docker-compose ps

# View resource usage (CPU, Memory)
docker stats

# Check disk usage
df -h
docker system df

# View system logs
journalctl -u epl-live -f
```

### Debugging

```bash
# Enter producer container
docker exec -it epl-producer bash

# Enter consumer container
docker exec -it epl-consumer bash

# Check Kafka topics
docker exec epl-kafka kafka-topics --bootstrap-server localhost:9092 --list

# Consume messages from Kafka (for debugging)
docker exec epl-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic epl.matches \
  --from-beginning

# Check Redis keys
docker exec -it epl-redis redis-cli
> KEYS *
> GET match:12345
```

---

## Updating Your Code

```bash
# From your local machine
rsync -avz -e "ssh -i ~/.ssh/epl-live-key.pem" \
  services/ \
  ec2-user@$INSTANCE_IP:/opt/epl-live/

# SSH into instance and restart
ssh -i ~/.ssh/epl-live-key.pem ec2-user@$INSTANCE_IP
cd /opt/epl-live
docker-compose down
docker-compose build
docker-compose up -d
```

---

## Auto-start on Reboot

The systemd service is automatically configured. Services will start on instance boot.

```bash
# Check service status
sudo systemctl status epl-live

# Manually start
sudo systemctl start epl-live

# Manually stop
sudo systemctl stop epl-live

# View service logs
sudo journalctl -u epl-live -f
```

---

## Instance Size Recommendations

### t3.micro (Free Tier - 12 months)
- **RAM**: 1GB
- **vCPUs**: 2
- **Cost**: $0/month (first 12 months), then ~$7/month
- **Good for**: Testing, low traffic
- **Limitations**: May struggle under heavy load
- **Tip**: Disable Kafka UI to save memory

### t3.small (Recommended) ⭐
- **RAM**: 2GB
- **vCPUs**: 2
- **Cost**: ~$15/month
- **Good for**: Production use
- **Benefits**: Smooth operation, room for growth

### Memory Usage Breakdown:
```
Kafka + ZooKeeper: ~768MB
Redis:             ~256MB
Producer:          ~128MB
Consumer:          ~128MB
System:            ~256MB
----------------------------
Total:             ~1.5GB

t3.micro: Tight fit (disable Kafka UI)
t3.small: Comfortable (recommended)
```

---

## Optimizing for t3.micro

If using t3.micro (1GB RAM), optimize memory:

```bash
# Edit docker-compose.yml to disable Kafka UI
docker-compose --profile debug up -d  # Kafka UI won't start

# Reduce Kafka heap size (already configured)
# KAFKA_HEAP_OPTS: "-Xmx512M -Xms512M"

# Reduce Redis max memory (already configured)
# maxmemory 256mb
```

---

## Security Best Practices

### 1. Restrict SSH Access

```bash
# Update terraform.tfvars with your IP
allowed_ssh_cidr = ["YOUR_PUBLIC_IP/32"]

# Apply changes
terraform apply
```

### 2. Create IAM User (Don't use root)

```bash
aws iam create-user --user-name epl-admin
aws iam attach-user-policy --user-name epl-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name epl-admin
```

### 3. Enable AWS CloudWatch (Optional - costs extra)

Set `enable_cloudwatch_logs = true` in `terraform.tfvars`

---

## Backup Strategy

### Backup Kafka Data

```bash
# On EC2 instance
docker run --rm \
  -v /var/lib/docker/volumes/epl-live_kafka-data:/data \
  -v /home/ec2-user/backups:/backup \
  alpine tar czf /backup/kafka-backup-$(date +%Y%m%d).tar.gz /data
```

### Backup to S3 (Optional)

```bash
# Install AWS CLI on instance
sudo dnf install awscli -y

# Backup to S3
aws s3 cp /home/ec2-user/backups/kafka-backup-20250106.tar.gz \
  s3://your-backup-bucket/kafka/
```

---

## Monitoring with CloudWatch (Optional)

Enable CloudWatch for better monitoring:

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure and start
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check Docker status
sudo systemctl status docker

# Check available memory
free -h

# Check disk space
df -h

# View Docker logs
docker-compose logs
```

### Out of Memory

```bash
# Check memory usage
free -h
docker stats

# Solutions:
# 1. Upgrade to t3.small
# 2. Disable Kafka UI
# 3. Reduce Kafka heap size
```

### Can't SSH into Instance

```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify key permissions
chmod 400 ~/.ssh/epl-live-key.pem

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>
```

### Kafka Connection Issues

```bash
# Check Kafka is running
docker-compose ps kafka

# Check Kafka logs
docker-compose logs kafka

# Test Kafka from inside producer
docker exec -it epl-producer bash
nc -zv kafka 9092
```

---

## Cost Breakdown

### t3.micro (Free Tier)
```
First 12 months:      $0/month
After 12 months:      ~$7/month
```

### t3.small (Recommended)
```
EC2 instance:         ~$15/month
Elastic IP:           $0 (free when instance running)
EBS Storage (20GB):   ~$2/month
Data Transfer:        $0 (within free tier)
-----------------------------------
Total:                ~$17/month
```

**Savings vs ECS/MSK deployment: ~$93/month (85% cheaper)**

---

## Cleanup / Destroy

```bash
# Stop services
ssh -i ~/.ssh/epl-live-key.pem ec2-user@$INSTANCE_IP
cd /opt/epl-live
docker-compose down -v

# Destroy infrastructure
cd infra/terraform-ec2
terraform destroy

# Delete key pair (optional)
aws ec2 delete-key-pair --key-name epl-live-key
rm ~/.ssh/epl-live-key.pem
```

---

## Next Steps

1. ✅ Deploy and verify all services are running
2. 🔒 **Restrict SSH access** to your IP only
3. 📊 Set up CloudWatch monitoring (optional)
4. 💾 Configure automated backups
5. 🚀 Consider upgrading to t3.small for production

---

## Comparison: EC2 vs Other Options

| Feature | EC2 Single Instance | ECS/Fargate | Fly.io | Convex-Only |
|---------|-------------------|-------------|---------|-------------|
| **Cost** | $0-17/month | $110/month | $0-25/month | $0-25/month |
| **Setup Time** | 30 min | 2 hours | 15 min | 1 hour |
| **Complexity** | Low | High | Very Low | Very Low |
| **Scalability** | Manual | Auto | Auto | Auto |
| **Maintenance** | You manage | AWS manages | Fly manages | Convex manages |
| **Free Tier** | ✅ 12 months | ❌ No | ✅ Forever | ✅ Forever |

---

## Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Check [Troubleshooting](#troubleshooting) section
3. Review Terraform outputs: `terraform output`
