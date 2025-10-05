from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import logging
from producer import send_event, close_producer
from api_client import fetch_epl_events

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Background task handle
poller_task = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage startup and shutdown events"""
    global poller_task
    # Startup
    logger.info("Starting EPL data poller...")
    poller_task = asyncio.create_task(poll_and_send())
    yield
    # Shutdown
    logger.info("Shutting down EPL data poller...")
    if poller_task:
        poller_task.cancel()
        try:
            await poller_task
        except asyncio.CancelledError:
            pass
    await close_producer()

app = FastAPI(title="EPL Data Producer", version="1.0.0", lifespan=lifespan)

async def poll_and_send():
    """Poll EPL API and send events to Kafka"""
    while True:
        try:
            logger.info("Fetching EPL events...")
            events = await fetch_epl_events()

            if events:
                logger.info(f"Fetched {len(events)} events")
                for event in events:
                    await send_event(event)
                logger.info(f"Successfully sent {len(events)} events to Kafka")
            else:
                logger.info("No events fetched")

        except Exception as e:
            logger.error(f"Error in poll_and_send: {e}", exc_info=True)

        await asyncio.sleep(5)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "epl-producer"}

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "EPL Data Producer",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "docs": "/docs"
        }
    }
