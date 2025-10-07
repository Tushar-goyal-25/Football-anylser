#!/bin/bash
set -e

# EPL Live - EC2 Setup Script
echo "========================================="
echo "EPL Live - Starting EC2 Setup"
echo "========================================="

# Update system
echo "[1/7] Updating system packages..."
dnf update -y

# Install Docker
echo "[2/7] Installing Docker..."
dnf install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
echo "[3/7] Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
echo "[4/7] Installing Git..."
dnf install git -y

# Create application directory
echo "[5/7] Setting up application directory..."
mkdir -p /opt/epl-live
cd /opt/epl-live

# Create docker-compose.yml
echo "[6/7] Creating docker-compose configuration..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: epl-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    volumes:
      - zookeeper-data:/var/lib/zookeeper/data
      - zookeeper-logs:/var/lib/zookeeper/log
    restart: unless-stopped
    networks:
      - epl-network

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: epl-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_LOG_SEGMENT_BYTES: 1073741824
      KAFKA_NUM_PARTITIONS: 3
    volumes:
      - kafka-data:/var/lib/kafka/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "kafka-broker-api-versions", "--bootstrap-server", "localhost:9092"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - epl-network

  redis:
    image: redis:7-alpine
    container_name: epl-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - epl-network

  producer:
    build:
      context: ./producer
      dockerfile: Dockerfile
    container_name: epl-producer
    depends_on:
      kafka:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
      - KAFKA_TOPIC=epl.matches
      - REDIS_URL=redis://redis:6379
      - FOOTBALL_API_KEY=$${FOOTBALL_API_KEY}
      - ENABLE_MOCK_DATA=$${ENABLE_MOCK_DATA:-false}
    restart: unless-stopped
    networks:
      - epl-network

  consumer:
    build:
      context: ./consumer
      dockerfile: Dockerfile
    container_name: epl-consumer
    depends_on:
      kafka:
        condition: service_healthy
    environment:
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
      - KAFKA_TOPIC=epl.matches
      - KAFKA_GROUP_ID=epl-consumer-group
      - CONVEX_URL=$${CONVEX_URL}
      - CONVEX_DEPLOY_KEY=$${CONVEX_DEPLOY_KEY}
    restart: unless-stopped
    networks:
      - epl-network

volumes:
  zookeeper-data:
  zookeeper-logs:
  kafka-data:
  redis-data:

networks:
  epl-network:
    driver: bridge
EOF

# Create environment file
echo "[6.5/7] Creating environment file..."
cat > .env <<EOF
FOOTBALL_API_KEY=${football_api_key}
CONVEX_URL=${convex_url}
CONVEX_DEPLOY_KEY=${convex_deploy_key}
ENABLE_MOCK_DATA=${enable_mock_data}
EOF

# Clone the repository (placeholder - user should update this)
echo "[7/7] Note: You need to copy your producer and consumer code to /opt/epl-live/"
echo "Run these commands after SSH-ing into the instance:"
echo "  git clone <your-repo-url> /tmp/repo"
echo "  cp -r /tmp/repo/services/producer /opt/epl-live/"
echo "  cp -r /tmp/repo/services/consumer /opt/epl-live/"
echo "  cd /opt/epl-live && docker-compose up -d"

# Create a systemd service to auto-start on boot
cat > /etc/systemd/system/epl-live.service <<'SYSTEMD_EOF'
[Unit]
Description=EPL Live Docker Compose Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/epl-live
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload
systemctl enable epl-live.service

# Set proper permissions
chown -R ec2-user:ec2-user /opt/epl-live

echo "========================================="
echo "EPL Live - EC2 Setup Complete!"
echo "========================================="
echo "Next steps:"
echo "1. SSH into the instance: ssh -i your-key.pem ec2-user@<instance-ip>"
echo "2. Copy your code: scp -r services/producer services/consumer ec2-user@<instance-ip>:/opt/epl-live/"
echo "3. Start services: cd /opt/epl-live && docker-compose up -d"
echo "========================================="
