from aiokafka import AIOKafkaConsumer
import json
import logging
import os
import asyncio
from transform import transform_event
from storage import write_to_dynamodb, write_to_s3, write_to_convex

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def run_consumer():
    """Run Kafka consumer to process EPL match events"""
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
    topic = os.getenv("KAFKA_TOPIC", "epl.matches")
    group_id = os.getenv("KAFKA_GROUP_ID", "epl-consumer-group")

    logger.info(f"Starting Kafka consumer for topic: {topic}")
    logger.info(f"Bootstrap servers: {bootstrap_servers}")
    logger.info(f"Consumer group: {group_id}")

    consumer = AIOKafkaConsumer(
        topic,
        bootstrap_servers=bootstrap_servers,
        group_id=group_id,
        auto_offset_reset='latest',
        enable_auto_commit=True,
        value_deserializer=lambda m: json.loads(m.decode('utf-8'))
    )

    await consumer.start()
    logger.info("Kafka consumer started successfully")

    try:
        async for msg in consumer:
            try:
                logger.info(f"Received message from topic {msg.topic}, partition {msg.partition}, offset {msg.offset}")

                # Parse message
                data = msg.value
                logger.debug(f"Message data: {data}")

                # Transform event
                transformed = transform_event(data)
                logger.info(f"Transformed event for match {transformed.get('match_id')}")

                # Write to Convex (real-time dashboard)
                await write_to_convex(transformed)

            except json.JSONDecodeError as e:
                logger.error(f"Failed to decode message: {e}")
            except Exception as e:
                logger.error(f"Error processing message: {e}", exc_info=True)

    except asyncio.CancelledError:
        logger.info("Consumer cancelled, shutting down...")
    except Exception as e:
        logger.error(f"Consumer error: {e}", exc_info=True)
    finally:
        await consumer.stop()
        logger.info("Kafka consumer stopped")

if __name__ == "__main__":
    asyncio.run(run_consumer())
