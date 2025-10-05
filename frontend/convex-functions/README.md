# Convex Backend Functions

This directory contains Convex serverless functions for the Live EPL dashboard.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Initialize Convex:
   ```bash
   npx convex dev
   ```

3. Follow the prompts to create a new Convex project or link to an existing one.

4. Copy the deployment URL to your Next.js `.env.local`:
   ```
   NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
   ```

## Functions

- `matches.ts` - Query and mutation functions for match data
  - `getLiveMatches` - Get all currently live matches
  - `getAllMatches` - Get all matches (live and recent)
  - `getMatchById` - Get a specific match by ID
  - `upsertMatch` - Insert or update match data
  - `deleteOldMatches` - Cleanup old matches

## Integration with Kafka Consumer

The Kafka consumer can write to Convex using the HTTP API or webhooks. See the deployment documentation for setup instructions.
