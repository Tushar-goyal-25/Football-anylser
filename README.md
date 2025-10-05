# Live EPL - Real-Time Premier League Data Pipeline & Dashboard

![Live EPL](https://img.shields.io/badge/status-MVP-green)
![License](https://img.shields.io/badge/license-MIT-blue)

A production-ready real-time streaming pipeline that ingests live Premier League match data, processes it through Apache Kafka, stores it in AWS (DynamoDB + S3), and displays live updates in a Next.js dashboard with Clerk authentication.

## 🏗️ Architecture

```
Public EPL API → FastAPI Producer → Kafka → Python Consumer → DynamoDB/S3
                      ↓                                            ↓
                 Docker Compose                              Convex Functions
                                                                   ↓
                                                        Next.js Dashboard + Clerk
```

## 🚀 Tech Stack

- **Streaming**: Apache Kafka (local: Docker Compose, prod: AWS MSK)
- **Producer API**: FastAPI (Python)
- **Consumer/Processing**: Python (aiokafka, async)
- **Storage**: AWS DynamoDB (live data) + S3 (historical snapshots)
- **Backend**: Convex (serverless functions)
- **Frontend**: Next.js 15, shadcn/ui, TailwindCSS
- **Auth**: Clerk
- **Containerization**: Docker & Docker Compose
- **Orchestration**: AWS ECS Fargate
- **IaC**: Terraform (optional)

## 📁 Project Structure

```
live-epl/
├── infra/
│   ├── docker-compose.yml          # Local dev environment
│   └── .env.example
├── services/
│   ├── producer/                   # FastAPI Kafka producer
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── producer.py
│   │   │   └── api_client.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── consumer/                   # Kafka consumer
│       ├── app/
│       │   ├── consumer.py
│       │   ├── transform.py
│       │   └── storage.py
│       ├── Dockerfile
│       └── requirements.txt
├── frontend/
│   ├── nextjs-app/                 # Next.js dashboard
│   │   ├── app/
│   │   ├── components/
│   │   └── package.json
│   └── convex-functions/           # Convex backend
│       ├── convex/
│       │   ├── schema.ts
│       │   └── matches.ts
│       └── package.json
└── deployments/
    ├── ecs-task-definitions/       # ECS task configs
    ├── terraform/                  # Infrastructure as Code
    └── DEPLOYMENT.md               # Deployment guide
```

## 🎯 Features

- ✅ Real-time EPL match data ingestion
- ✅ Kafka-based event streaming
- ✅ Live data processing and transformation
- ✅ DynamoDB for low-latency reads
- ✅ S3 for historical analytics
- ✅ Real-time dashboard with Convex
- ✅ User authentication with Clerk
- ✅ Docker containerization
- ✅ AWS deployment ready (MSK + ECS)

## 🏃 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ (for frontend)
- Python 3.12+ (for local development)
- Football API key (optional, uses mock data without it)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Football-analyser
   ```

2. **Set up environment variables**
   ```bash
   # Copy example env files
   cp infra/.env.example infra/.env
   cp services/producer/.env.example services/producer/.env
   cp services/consumer/.env.example services/consumer/.env
   ```

3. **Get Football API key (optional)**
   - Register at [Football-Data.org](https://www.football-data.org/client/register)
   - Add to `infra/.env`: `FOOTBALL_API_KEY=your_key_here`
   - Without a key, the system will use mock data

4. **Start the backend services**
   ```bash
   cd infra
   docker-compose up -d
   ```

   This starts:
   - Zookeeper (port 2181)
   - Kafka (port 9092)
   - Kafka UI (port 8080) - View at http://localhost:8080
   - Producer (port 8000) - API at http://localhost:8000
   - Consumer

5. **Setup Convex**
   ```bash
   cd frontend/convex-functions
   npm install
   npx convex dev
   # Follow prompts to create/link Convex project
   # Copy deployment URL
   ```

6. **Setup Clerk**
   - Create account at [Clerk.dev](https://clerk.dev)
   - Create new application
   - Copy publishable key and secret key

7. **Setup Next.js frontend**
   ```bash
   cd frontend/nextjs-app
   npm install

   # Create .env.local
   cat > .env.local << EOF
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
   CLERK_SECRET_KEY=your_clerk_secret_key
   NEXT_PUBLIC_CONVEX_URL=your_convex_deployment_url
   EOF

   npm run dev
   ```

8. **Access the dashboard**
   - Frontend: http://localhost:3000
   - Producer API: http://localhost:8000/docs
   - Kafka UI: http://localhost:8080

### Verify Data Flow

1. Check producer logs:
   ```bash
   docker logs -f epl-producer
   ```

2. Check consumer logs:
   ```bash
   docker logs -f epl-consumer
   ```

3. View Kafka messages in Kafka UI: http://localhost:8080

4. View live data in dashboard: http://localhost:3000

## 🌐 Production Deployment

See [DEPLOYMENT.md](deployments/DEPLOYMENT.md) for detailed AWS deployment instructions.

### Quick Deploy Steps

1. Setup AWS infrastructure (Terraform or manual)
2. Create MSK cluster
3. Build and push Docker images to ECR
4. Deploy ECS services
5. Configure Convex and Clerk
6. Deploy Next.js to Vercel/Amplify

## 📊 API Documentation

### Producer API

- `GET /` - Service info
- `GET /health` - Health check
- `GET /docs` - Swagger UI

### Convex Functions

- `getLiveMatches` - Get all live matches
- `getAllMatches` - Get all matches
- `getMatchById(matchId)` - Get specific match
- `upsertMatch(...)` - Update match data

## 🧪 Testing

### Test Producer
```bash
curl http://localhost:8000/health
```

### Test Kafka
View messages in Kafka UI or use:
```bash
docker exec -it epl-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic epl.matches \
  --from-beginning
```

### Test Consumer
Check logs for processing confirmation:
```bash
docker logs epl-consumer
```

## 📈 Monitoring

### Local Development
- Kafka UI: http://localhost:8080
- Producer logs: `docker logs epl-producer`
- Consumer logs: `docker logs epl-consumer`

### Production (AWS)
- CloudWatch Logs: `/ecs/epl-producer`, `/ecs/epl-consumer`
- CloudWatch Metrics: ECS, MSK, DynamoDB
- Convex Dashboard: Real-time function metrics

## 🔧 Configuration

### Kafka Topics
- `epl.matches` - Match events stream

### Environment Variables

**Producer**:
- `KAFKA_BOOTSTRAP_SERVERS` - Kafka brokers
- `KAFKA_TOPIC` - Topic name
- `FOOTBALL_API_KEY` - Football API key

**Consumer**:
- `KAFKA_BOOTSTRAP_SERVERS` - Kafka brokers
- `KAFKA_TOPIC` - Topic name
- `KAFKA_GROUP_ID` - Consumer group
- `DYNAMODB_TABLE` - DynamoDB table name
- `S3_BUCKET` - S3 bucket name
- `USE_LOCAL_MOCK` - Use mock storage (local dev)

**Frontend**:
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` - Clerk public key
- `CLERK_SECRET_KEY` - Clerk secret
- `NEXT_PUBLIC_CONVEX_URL` - Convex deployment URL

## 🛠️ Development

### Add New Features

1. **Add new event types**: Update `api_client.py` in producer
2. **Add transformations**: Update `transform.py` in consumer
3. **Add UI components**: Use shadcn/ui in `components/`
4. **Add Convex functions**: Create in `convex-functions/convex/`

### Code Style

- Python: Follow PEP 8
- TypeScript: ESLint + Prettier
- Use async/await for I/O operations

## 📝 Production Checklist

- [ ] Add retries and exponential backoff for API calls
- [ ] Add idempotency to producer events
- [ ] Add schema validation (Pydantic) for events
- [ ] Add unit tests & integration tests
- [ ] Add IAM least privilege for ECS tasks
- [ ] Enable encryption at rest (S3, DynamoDB)
- [ ] Enable TLS in transit
- [ ] Add autoscaling rules for ECS tasks
- [ ] Set up CloudWatch alarms
- [ ] Configure S3 lifecycle policies

## 🐛 Troubleshooting

### Producer not fetching data
- Check API key in `.env`
- Verify API rate limits
- Check logs: `docker logs epl-producer`

### Consumer not processing
- Verify Kafka connectivity
- Check consumer group status in Kafka UI
- Check logs: `docker logs epl-consumer`

### Frontend not showing data
- Verify Convex deployment URL
- Check Clerk authentication setup
- Check browser console for errors

## 📚 Resources

- [Football-Data.org API](https://www.football-data.org/documentation)
- [Apache Kafka Docs](https://kafka.apache.org/documentation/)
- [AWS MSK Docs](https://docs.aws.amazon.com/msk/)
- [Convex Docs](https://docs.convex.dev/)
- [Clerk Docs](https://clerk.dev/docs)
- [Next.js Docs](https://nextjs.org/docs)
- [shadcn/ui](https://ui.shadcn.com/)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙋 Support

For issues and questions:
- Check [Troubleshooting](#-troubleshooting) section
- Open an issue on GitHub
- Check CloudWatch logs for production issues

## 🎯 Roadmap

- [ ] Add more EPL statistics (possession, shots, cards)
- [ ] Add match predictions/analytics
- [ ] Add historical data analysis
- [ ] Add email/SMS alerts for goals
- [ ] Add mobile app (React Native)
- [ ] Add GraphQL API layer
- [ ] Add Apache Spark for batch processing

---

**Built with ⚽ for football fans and data engineers**
