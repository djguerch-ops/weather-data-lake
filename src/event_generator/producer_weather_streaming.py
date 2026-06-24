import json
import random
import time
import uuid
from datetime import datetime, timezone

import boto3

STREAM_NAME = "weather-events-stream"
AWS_REGION = "eu-west-1"

CITIES = [
    {"city": "Paris", "country": "FR"},
    {"city": "Berlin", "country": "DE"},
    {"city": "Madrid", "country": "ES"},
    {"city": "Rome", "country": "IT"},
]

CONDITIONS = ["sunny", "cloudy", "rainy", "stormy", "windy"]
STATION_IDS = [f"ST_{i:03d}" for i in range(1, 11)]

kinesis = boto3.client("kinesis", region_name=AWS_REGION)


def generate_weather_event() -> dict:
    city_info = random.choice(CITIES)
    condition = random.choice(CONDITIONS)
    return {
        "event_id": str(uuid.uuid4()),
        "station_id": random.choice(STATION_IDS),
        "city": city_info["city"],
        "country": city_info["country"],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "temperature_c": round(random.uniform(-5, 40), 1),
        "humidity_pct": random.randint(20, 100),
        "wind_speed_kmh": round(random.uniform(0, 120), 1),
        "condition": condition,
        "is_extreme": condition == "stormy" or random.uniform(0, 40) > 35
    }


def run(n_events: int = 100, delay_seconds: float = 0.2) -> None:
    for i in range(n_events):
        event = generate_weather_event()
        kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(event).encode("utf-8"),
            PartitionKey=event["station_id"],
        )
        print(f"[{i+1}/{n_events}] sent {event['condition']} @ {event['city']}")
        time.sleep(delay_seconds)
    print(f"Done — {n_events} events streamed to {STREAM_NAME}")


if __name__ == "__main__":
    run(n_events=100, delay_seconds=0.2)