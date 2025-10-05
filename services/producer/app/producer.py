from aiokafka import AIOKafkaProducer
import json
import logging
import os
import asyncio

logger = logging.getLogger(__name__)

producer = None
producer_lock = asyncio.Lock()

async def get_producer():
    """Get or create Kafka producer instance"""
    global producer

    async with producer_lock:
        if producer is None:
            bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
            logger.info(f"Initializing Kafka producer with bootstrap servers: {bootstrap_servers}")

            producer = AIOKafkaProducer(
                bootstrap_servers=bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                compression_type='gzip',
                max_batch_size=16384,
                linger_ms=10,
            )
            await producer.start()
            logger.info("Kafka producer started successfully")

        return producer

async def send_event(event: dict):
    """Send event to Kafka topic"""
    try:
        p = await get_producer()
        topic = os.getenv("KAFKA_TOPIC", "epl.matches")

        # Add metadata
        event_with_metadata = {
            **event,
            "producer_timestamp": asyncio.get_event_loop().time()
        }

        await p.send_and_wait(topic, value=event_with_metadata)
        logger.debug(f"Event sent to topic {topic}: {event.get('event_type', 'unknown')}")

    except Exception as e:
        logger.error(f"Error sending event to Kafka: {e}", exc_info=True)
        raise

async def close_producer():
    """Close Kafka producer"""
    global producer
    if producer is not None:
        logger.info("Closing Kafka producer...")
        await producer.stop()
        producer = None
        logger.info("Kafka producer closed")
