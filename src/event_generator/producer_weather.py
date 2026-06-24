import json
import random
import uuid
from datetime import datetime, timezone
from pathlib import Path

CITIES = [
    {"city": "Paris", "country": "FR"},
    {"city": "Berlin", "country": "DE"},
    {"city": "Madrid", "country": "ES"},
    {"city": "Rome", "country": "IT"},
]

CONDITIONS = ["sunny", "cloudy", "rainy", "stormy", "windy"]
STATION_IDS = [f"ST_{i:03d}" for i in range(1, 11)]


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


def generate_events_file(output_path: str, n: int = 1000) -> None:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as f:
        for _ in range(n):
            f.write(json.dumps(generate_weather_event()) + "\n")


if __name__ == "__main__":
    generate_events_file("data/sample/weather_events.json", n=1000)
    print("Fichier généré : data/sample/weather_events.json")