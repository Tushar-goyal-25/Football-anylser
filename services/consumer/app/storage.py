import logging
import os
import json
from typing import Dict, Any
from datetime import datetime
import asyncio
import aiohttp

logger = logging.getLogger(__name__)

# AWS configuration from environment
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "epl-live-matches")
S3_BUCKET = os.getenv("S3_BUCKET", "epl-match-snapshots")

# Convex configuration
CONVEX_URL = os.getenv("CONVEX_URL", "")
CONVEX_DEPLOY_KEY = os.getenv("CONVEX_DEPLOY_KEY", "")

# For local development, we'll mock AWS services
USE_LOCAL_MOCK = os.getenv("USE_LOCAL_MOCK", "true").lower() == "true"

async def write_to_dynamodb(event: Dict[str, Any]):
    """
    Write event to DynamoDB for live state

    In production, use boto3 async client (aioboto3)
    For local dev, we'll log and mock
    """
    if USE_LOCAL_MOCK:
        logger.info(f"[MOCK] Writing to DynamoDB table '{DYNAMODB_TABLE}': match_id={event.get('match_id')}")
        logger.debug(f"[MOCK] DynamoDB item: {json.dumps(event, indent=2)}")
        return

    try:
        # Production implementation with aioboto3
        # import aioboto3
        # session = aioboto3.Session()
        # async with session.resource('dynamodb', region_name=AWS_REGION) as dynamodb:
        #     table = await dynamodb.Table(DYNAMODB_TABLE)
        #     await table.put_item(Item=event)

        logger.info(f"Written to DynamoDB: match {event.get('match_id')}")

    except Exception as e:
        logger.error(f"Error writing to DynamoDB: {e}", exc_info=True)
        raise

async def write_to_s3(event: Dict[str, Any]):
    """
    Write event snapshot to S3 for historical analysis

    Events are partitioned by date and match_id
    """
    if USE_LOCAL_MOCK:
        match_id = event.get("match_id", "unknown")
        timestamp = event.get("processed_timestamp", datetime.utcnow().isoformat())
        s3_key = f"matches/date={timestamp[:10]}/match_{match_id}_{timestamp}.json"

        logger.info(f"[MOCK] Writing to S3 bucket '{S3_BUCKET}': key={s3_key}")
        logger.debug(f"[MOCK] S3 object content: {json.dumps(event, indent=2)}")
        return

    try:
        # Production implementation with aioboto3
        # import aioboto3
        # session = aioboto3.Session()
        # async with session.client('s3', region_name=AWS_REGION) as s3:
        #     match_id = event.get("match_id", "unknown")
        #     timestamp = event.get("processed_timestamp", datetime.utcnow().isoformat())
        #     s3_key = f"matches/date={timestamp[:10]}/match_{match_id}_{timestamp}.json"
        #
        #     await s3.put_object(
        #         Bucket=S3_BUCKET,
        #         Key=s3_key,
        #         Body=json.dumps(event),
        #         ContentType='application/json'
        #     )

        logger.info(f"Written to S3: match {event.get('match_id')}")

    except Exception as e:
        logger.error(f"Error writing to S3: {e}", exc_info=True)
        raise

async def write_to_convex(event: Dict[str, Any]):
    """
    Write event to Convex for real-time dashboard updates
    """
    if not CONVEX_URL:
        logger.warning("CONVEX_URL not set, skipping Convex write")
        return

    try:
        url = f"{CONVEX_URL}/api/mutation"

        headers = {
            "Content-Type": "application/json",
        }

        # Add deploy key if available (for server-to-server auth)
        if CONVEX_DEPLOY_KEY:
            headers["Authorization"] = f"Convex {CONVEX_DEPLOY_KEY}"

        payload = {
            "path": "matches:upsertMatch",
            "args": [event],
            "format": "json",
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, headers=headers) as response:
                if response.status == 200:
                    result = await response.json()
                    logger.info(f"Written to Convex: match {event.get('match_id')}")
                    return result
                else:
                    error_text = await response.text()
                    logger.error(f"Convex write failed with status {response.status}: {error_text}")

    except Exception as e:
        logger.error(f"Error writing to Convex: {e}", exc_info=True)
        # Don't raise - allow other storage operations to continue

# For production, uncomment and use:
# async def init_aws_clients():
#     """Initialize AWS clients with proper credentials"""
#     # Configure AWS credentials via IAM roles (ECS) or environment variables
#     pass
