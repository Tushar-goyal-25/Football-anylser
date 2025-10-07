# ⚽ EPL Live - Real-time English Premier League Match Tracker

A real-time data pipeline and analytics platform for English Premier League matches, featuring live match updates, team statistics, and intelligent caching.

**🌐 Live Demo:** [https://epl-analysis-r3n13ort6-tushar-goyal-25s-projects.vercel.app](https://epl-analysis-r3n13ort6-tushar-goyal-25s-projects.vercel.app)

![Status](https://img.shields.io/badge/status-Production-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-AWS%20EC2-orange)

---

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Cost Breakdown](#cost-breakdown)
- [Contributing](#contributing)

---

## ✨ Features

### Frontend
- 🎨 **Modern UI** - Beautiful, responsive design with dark mode support
- ⚡ **Real-time Updates** - Live match scores and statistics via Convex
- 🔍 **Smart Search** - Filter matches by team name
- ⭐ **Favorite Teams** - Mark and filter your favorite teams
- 📊 **Live Statistics** - Real-time match stats and KPIs
- 🌙 **Dark Mode** - System preference detection with manual toggle

### Backend
- 🔄 **Event-Driven Architecture** - Apache Kafka for streaming match events
- 🧠 **Adaptive Caching** - Smart Redis caching based on match state:
  - Live matches: 30-second polling
  - No live matches: 10-minute polling
  - Finished matches: 24-hour cache
- 📡 **Real-time Database** - Convex for instant frontend updates
- 🚀 **Scalable Infrastructure** - AWS EC2 with auto-deployment

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS EC2 Instance                         │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────┐             │
│  │   Producer   │──│   Kafka     │──│  Consumer  │             │
│  │ (API Fetch)  │  │ (Streaming) │  │ (Process)  │             │
│  └──────┬───────┘  └─────────────┘  └─────┬──────┘             │
│         │                                   │                    │
│         │          ┌─────────────┐          │                    │
│         └──────────│    Redis    │──────────┘                    │
│                    │  (Caching)  │                               │
│                    └─────────────┘                               │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │     Convex      │
                          │   (Database)    │
                          └────────┬────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │   Next.js App   │
                          │  (Frontend UI)  │
                          └─────────────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │   Vercel CDN    │
                          │  (Deployment)   │
                          └─────────────────┘
```

### Data Flow

1. **Producer** → Fetches match data from Football-Data.org API
2. **Redis** → Caches finished matches and controls polling intervals
3. **Kafka** → Streams match events in real-time
4. **Consumer** → Processes events and writes to Convex
5. **Convex** → Real-time database with automatic frontend sync
6. **Next.js** → Displays live data to users via Vercel

---

## 🛠️ Tech Stack

### Frontend
- **Framework:** Next.js 14 (App Router)
- **Styling:** Tailwind CSS
- **UI Components:** Lucide React Icons
- **Real-time Data:** Convex React Hooks
- **Authentication:** Clerk
- **Deployment:** Vercel
- **Language:** TypeScript

### Backend
- **Runtime:** Python 3.12
- **Message Broker:** Apache Kafka (Confluent Platform)
- **Cache:** Redis 7
- **Database:** Convex (Real-time)
- **API:** Football-Data.org
- **Containerization:** Docker & Docker Compose

### Infrastructure
- **Cloud Provider:** AWS
- **Compute:** EC2 (t3.small)
- **Storage:** EBS (30GB)
- **Networking:** VPC, Security Groups, Elastic IP
- **IaC:** Terraform
- **CI/CD:** GitHub Actions

---

## 📁 Project Structure

```
Football-analyser/
├── epl-analysis/                  # Next.js Frontend
│   ├── app/                       # Next.js 14 App Router
│   │   ├── page.tsx              # Main dashboard
│   │   └── globals.css           # Global styles
│   ├── components/               # React components
│   │   ├── MatchCard.tsx         # Match display card
│   │   └── MatchStats.tsx        # Statistics component
│   ├── convex/                   # Convex backend functions
│   │   └── matches.ts            # Match queries/mutations
│   └── public/                   # Static assets
│
├── services/                      # Backend Services
│   ├── producer/                 # Data Producer
│   │   ├── app/
│   │   │   ├── main.py          # Producer entry point
│   │   │   ├── api_client.py    # API client with caching
│   │   │   ├── cache.py         # Redis cache logic
│   │   │   └── kafka_producer.py # Kafka producer
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   │
│   └── consumer/                 # Data Consumer
│       ├── app/
│       │   ├── main.py          # Consumer entry point
│       │   ├── kafka_consumer.py # Kafka consumer
│       │   └── convex_client.py # Convex integration
│       ├── Dockerfile
│       └── requirements.txt
│
├── infra/                        # Infrastructure
│   ├── terraform-ec2/           # EC2 Deployment (Production)
│   │   ├── main.tf              # Main Terraform config
│   │   ├── ec2.tf               # EC2 instance
│   │   ├── variables.tf         # Variables
│   │   ├── outputs.tf           # Outputs
│   │   ├── user-data.sh         # EC2 initialization script
│   │   └── terraform.tfvars     # Configuration values
│   │
│   ├── docker-compose.yml       # Local development
│   └── docker-compose.ec2.yml   # EC2 optimized config
│
├── .github/
│   └── workflows/
│       ├── deploy-ec2.yml       # EC2 CI/CD pipeline
│       └── deploy-frontend.yml  # Vercel CI/CD pipeline
│
├── DEPLOYMENT-EC2.md            # EC2 deployment guide
└── README.md                    # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** 20+
- **Python** 3.12+
- **Docker** & Docker Compose
- **AWS Account** (for deployment)
- **Football-Data.org API Key** ([Get one free](https://www.football-data.org/))
- **Convex Account** ([Sign up free](https://convex.dev))

### Local Development

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/Football-analyser.git
cd Football-analyser
```

#### 2. Setup Frontend

```bash
cd epl-analysis

# Install dependencies
npm install

# Setup Convex
npx convex dev

# Create .env.local
cat > .env.local << EOF
CONVEX_DEPLOYMENT=dev:your-deployment-name
NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your-clerk-key
CLERK_SECRET_KEY=your-clerk-secret
EOF

# Start development server
npm run dev
```

Frontend runs at: http://localhost:3000

#### 3. Setup Backend Services

```bash
cd infra

# Create .env file
cat > .env << EOF
FOOTBALL_API_KEY=your-api-key
CONVEX_URL=https://your-deployment.convex.cloud
ENABLE_MOCK_DATA=false
EOF

# Start services
docker-compose up -d

# View logs
docker-compose logs -f
```

Services running:
- Kafka: `localhost:9092`
- Redis: `localhost:6379`
- Kafka UI: http://localhost:8080

---

## 🌐 Deployment

### AWS EC2 Deployment ($0-17/month)

Complete guide: [DEPLOYMENT-EC2.md](DEPLOYMENT-EC2.md)

**Quick Start:**

```bash
# 1. Create SSH key
aws ec2 create-key-pair \
  --key-name epl-live-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/epl-live-key.pem
chmod 400 ~/.ssh/epl-live-key.pem

# 2. Deploy infrastructure
cd infra/terraform-ec2
terraform init
terraform apply

# 3. Copy services
INSTANCE_IP=$(terraform output -raw instance_public_ip)
scp -i ~/.ssh/epl-live-key.pem -r ../../services/producer ec2-user@$INSTANCE_IP:/opt/epl-live/
scp -i ~/.ssh/epl-live-key.pem -r ../../services/consumer ec2-user@$INSTANCE_IP:/opt/epl-live/

# 4. Start services
ssh -i ~/.ssh/epl-live-key.pem ec2-user@$INSTANCE_IP
cd /opt/epl-live
docker-compose build
docker-compose up -d
```

### Frontend Deployment (Vercel)

```bash
cd epl-analysis

# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

---

## 🔄 CI/CD Pipeline

### Backend (EC2) - Automated on Push

Workflow: `.github/workflows/deploy-ec2.yml`

1. ✅ **Lint & Test** - Python code quality checks
2. ✅ **Get EC2 IP** - Automatically find instance
3. ✅ **Copy Services** - Deploy producer/consumer code
4. ✅ **Restart Containers** - Build and restart Docker services
5. ✅ **Verify Deployment** - Health checks

**GitHub Secrets Required:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_SSH_PRIVATE_KEY_BASE64`

### Frontend (Vercel) - Automated on Push

Workflow: `.github/workflows/deploy-frontend.yml`

1. ✅ **Lint & Type Check** - ESLint and TypeScript validation
2. ✅ **Build** - Next.js production build
3. ✅ **Deploy** - Deploy to Vercel CDN

**GitHub Secrets Required:**
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

---

## 💰 Cost Breakdown

### Production Deployment

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **EC2 Instance** | t3.small (2 vCPU, 2GB RAM) | $15.00 |
| **EBS Storage** | 30GB gp3 | $2.40 |
| **Elastic IP** | (while instance running) | $0.00 |
| **Data Transfer** | ~10GB/month | $0.00 (free tier) |
| **Vercel** | Hobby plan | $0.00 |
| **Convex** | Free tier | $0.00 |
| **GitHub Actions** | Public repo | $0.00 |
| **Total** | | **~$17/month** |

**Free Tier Benefits:**
- First 12 months: **t3.micro FREE** (then $7/month)
- 30GB EBS storage: FREE
- 100GB data transfer: FREE

---

## 📊 Key Features

### Adaptive Caching Strategy

The system intelligently adjusts API polling based on match state:

```python
# Live matches (IN_PLAY)
poll_interval = 30 seconds

# No live matches
poll_interval = 10 minutes

# Finished matches
cache_duration = 24 hours
```

**Benefits:**
- ✅ Reduces API calls by 95-99%
- ✅ Stays within free tier (10 calls/minute)
- ✅ Real-time updates when needed

### Real-time Architecture

**Convex Real-time Database:**
- Automatic frontend sync (no polling needed)
- Optimistic updates
- Built-in caching
- TypeScript type safety

**Kafka Event Streaming:**
- Decoupled producer/consumer
- Guaranteed message delivery
- Scalable architecture
- Event replay capability

---

## 🔧 Environment Variables

### Frontend (.env.local)

```bash
NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

### Backend (infra/.env)

```bash
FOOTBALL_API_KEY=your-api-key
CONVEX_URL=https://your-deployment.convex.cloud
ENABLE_MOCK_DATA=false
```

### Terraform (infra/terraform-ec2/terraform.tfvars)

```hcl
aws_region          = "us-east-1"
instance_type       = "t3.small"
ssh_key_name        = "epl-live-key"
football_api_key    = "your-api-key"
convex_url          = "https://your-deployment.convex.cloud"
allowed_ssh_cidr    = ["0.0.0.0/0"]
```

---

## 🐛 Troubleshooting

### Frontend Issues

**Deployment fails on Vercel:**
```bash
npm run build  # Check for errors locally
```

**No data showing:**
```bash
npx convex dev  # Verify Convex connection
```

### Backend Issues

**Services not starting:**
```bash
docker-compose logs producer
docker-compose logs consumer
docker-compose down && docker-compose build --no-cache && docker-compose up -d
```

**Kafka connection errors:**
```bash
docker-compose ps
docker exec epl-kafka kafka-topics --list --bootstrap-server localhost:9092
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Football-Data.org** - Free EPL match data API
- **Convex** - Real-time database platform
- **Vercel** - Frontend hosting and deployment
- **Confluent** - Kafka Docker images

---

**Built with ❤️ for EPL fans worldwide**

⭐ Star this repo if you find it useful!
