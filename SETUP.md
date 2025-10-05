# Live EPL Setup Guide

Complete setup instructions for the real-time EPL data pipeline.

## 🎯 Overview

This project streams live EPL match data through Kafka, processes it, stores in AWS/Convex, and displays in a Next.js dashboard.

## 📋 Prerequisites

- Docker Desktop installed and running
- Node.js 18+ installed
- Football API key from [Football-Data.org](https://www.football-data.org/client/register)
- Convex account (sign up at [convex.dev](https://www.convex.dev))
- Clerk account (sign up at [clerk.dev](https://clerk.dev))

## 🚀 Quick Start

### Step 1: Set up Convex (Already Done ✅)

Your Convex is already configured in `/epl-analysis`. Get your deployment URL:

```bash
cd /Users/tushar/Football-analyser/epl-analysis
npx convex dev
```

Copy the Convex URL shown in the terminal (format: `https://xxx.convex.cloud`)

### Step 2: Configure Environment Variables

#### A. Kafka Pipeline (infra/.env)

```bash
cd /Users/tushar/Football-analyser/infra
cp .env.example .env
```

Edit `.env` and add:
```bash
# Your Football API key
FOOTBALL_API_KEY=your_actual_api_key_here

# Your Convex deployment URL
CONVEX_URL=https://your-deployment.convex.cloud

# Optional: Convex deploy key for server-to-server auth
CONVEX_DEPLOY_KEY=your_deploy_key_here
```

#### B. Next.js Dashboard (epl-analysis/.env.local)

Your `.env.local` should already have:
```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
```

### Step 3: Start the Kafka Pipeline

```bash
cd /Users/tushar/Football-analyser/infra
docker compose up -d
```

This starts:
- ✅ Zookeeper (port 2181)
- ✅ Kafka (port 9092)
- ✅ Kafka UI (port 8080) - http://localhost:8080
- ✅ Producer (port 8000) - http://localhost:8000/docs
- ✅ Consumer (processing events)

**Verify the pipeline:**
```bash
# Check logs
docker logs -f epl-producer
docker logs -f epl-consumer

# View Kafka UI
open http://localhost:8080

# Check producer API
open http://localhost:8000/docs
```

### Step 4: Start the Dashboard

```bash
cd /Users/tushar/Football-analyser/epl-analysis
npm run dev
```

Open http://localhost:3000

### Step 5: Verify End-to-End Flow

1. **Check Producer** is polling the API:
   ```bash
   docker logs epl-producer | grep "Fetched"
   ```

2. **Check Kafka** has messages:
   - Open http://localhost:8080
   - Navigate to Topics → `epl.matches`
   - View messages

3. **Check Consumer** is processing:
   ```bash
   docker logs epl-consumer | grep "Written to Convex"
   ```

4. **Check Convex** has data:
   - Open Convex dashboard
   - Go to Data → matches table
   - Should see match records

5. **Check Dashboard** shows matches:
   - Sign in at http://localhost:3000
   - Should see live matches (or message if no live games)

## 🔧 Configuration Details

### Convex Functions

Located in `/epl-analysis/convex/`:

- **schema.ts** - Database schema for matches
- **matches.ts** - Query and mutation functions
  - `getLiveMatches()` - Get all live matches
  - `getAllMatches()` - Get all recent matches
  - `getMatchById(matchId)` - Get specific match
  - `upsertMatch(...)` - Insert/update match data

### Kafka Consumer → Convex Integration

The consumer (`services/consumer/app/storage.py`) writes to Convex via HTTP API:

```python
# Writes to Convex mutation endpoint
await write_to_convex(transformed_event)
```

**Environment variables needed:**
- `CONVEX_URL` - Your Convex deployment URL
- `CONVEX_DEPLOY_KEY` - (Optional) For server-to-server auth

### Dashboard Components

Located in `/epl-analysis/components/`:

- **MatchCard.tsx** - Display individual match
- **MatchStats.tsx** - Display statistics and charts

## 🐛 Troubleshooting

### Producer not fetching data
```bash
# Check if API key is set
docker exec epl-producer env | grep FOOTBALL_API_KEY

# Without API key, it uses mock data (this is normal)
docker logs epl-producer | grep "mock"
```

### Consumer not writing to Convex
```bash
# Check Convex URL is set
docker exec epl-consumer env | grep CONVEX_URL

# Check consumer logs for errors
docker logs epl-consumer | grep -i error
```

### Dashboard shows no matches
1. Ensure Convex is running: `cd epl-analysis && npx convex dev`
2. Check Convex has data in dashboard
3. Verify `NEXT_PUBLIC_CONVEX_URL` in epl-analysis/.env.local
4. Check browser console for errors

### Docker issues
```bash
# Restart services
docker compose down
docker compose up -d

# Rebuild if code changed
docker compose up -d --build

# View all logs
docker compose logs -f
```

## 📊 Monitoring

### Local Development

- **Kafka UI**: http://localhost:8080
  - View topics, messages, consumer groups

- **Producer API**: http://localhost:8000/docs
  - Swagger UI for FastAPI endpoints
  - Health check: http://localhost:8000/health

- **Convex Dashboard**: https://dashboard.convex.dev
  - View database tables
  - Monitor function calls
  - View logs

### Logs

```bash
# All services
docker compose logs -f

# Specific service
docker logs -f epl-producer
docker logs -f epl-consumer
docker logs -f epl-kafka
```

## 🎯 Testing the Pipeline

### 1. Test with Mock Data (No API Key)

The producer automatically uses mock data if no API key is provided:

```bash
# Should see mock data in logs
docker logs epl-producer | grep -i mock
```

### 2. Test with Real API

1. Get API key from https://www.football-data.org/client/register
2. Add to `infra/.env`: `FOOTBALL_API_KEY=your_key`
3. Restart: `docker compose restart producer`
4. Check logs: `docker logs -f epl-producer`

### 3. Manually Send Test Event

```bash
# Send test message to Kafka
docker exec -it epl-kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic epl.matches

# Paste this JSON and hit Enter:
{"event_type":"match_update","match_id":"99999","competition":"Premier League","status":"IN_PLAY","home_team":{"id":"1","name":"Test FC","short_name":"Test","tla":"TST"},"away_team":{"id":"2","name":"Demo United","short_name":"Demo","tla":"DMO"},"score":{"home":2,"away":1,"half_time_home":1,"half_time_away":0},"timestamp":"2025-10-05T22:00:00Z"}

# Ctrl+C to exit
```

Check consumer processes it: `docker logs epl-consumer | tail -20`

## 🚀 Next Steps

### Add More Features

1. **Real-time updates** - Matches update every 5 seconds
2. **Historical data** - Query past matches from S3
3. **Notifications** - Alert on goals/events
4. **Analytics** - Team statistics, predictions

### Deploy to Production

See [DEPLOYMENT.md](deployments/DEPLOYMENT.md) for AWS deployment guide.

## 📝 Common Commands

```bash
# Start everything
cd infra && docker compose up -d
cd epl-analysis && npm run dev

# Stop everything
docker compose down
# (Dashboard: Ctrl+C)

# View logs
docker compose logs -f
docker logs -f epl-producer
docker logs -f epl-consumer

# Rebuild after code changes
docker compose up -d --build

# Reset everything
docker compose down -v
docker compose up -d --build
```

## 🆘 Getting Help

- Check logs first: `docker compose logs -f`
- Verify environment variables are set
- Ensure Docker is running
- Confirm Convex dev is running
- Check Kafka UI for messages: http://localhost:8080

## ✅ Success Checklist

- [ ] Docker Desktop running
- [ ] Convex deployment URL copied
- [ ] Environment variables configured (`infra/.env` and `epl-analysis/.env.local`)
- [ ] Docker compose started successfully
- [ ] Producer fetching data (check logs)
- [ ] Consumer processing events (check logs)
- [ ] Kafka UI shows messages (http://localhost:8080)
- [ ] Convex has match data (check dashboard)
- [ ] Next.js dashboard running (http://localhost:3000)
- [ ] Can sign in with Clerk
- [ ] Matches display in dashboard

---

**Need help?** Check the troubleshooting section above or review the logs for error messages.
