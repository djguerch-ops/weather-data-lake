"""
Lambda handler: consumes Kinesis weather events and writes them to S3
as newline-delimited JSON, partitioned by date.
"""

import base64
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")

TARGET_BUCKET = os.environ["TARGET_BUCKET"]
TARGET_PREFIX = os.environ.get("TARGET_PREFIX", "streaming/events")


def lambda_handler(event, context):
    records = event.get("Records", [])
    if not records:
        return {"statusCode": 200, "processed": 0}

    decoded_events = []
    for record in records:
        payload_b64 = record["kinesis"]["data"]
        payload_bytes = base64.b64decode(payload_b64)
        try:
            decoded_events.append(json.loads(payload_bytes))
        except json.JSONDecodeError:
            print(f"Skipping malformed record: {payload_bytes[:200]}")
            continue

    if not decoded_events:
        return {"statusCode": 200, "processed": 0}

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    file_id = uuid.uuid4().hex
    key = f"{TARGET_PREFIX}/date={today}/{file_id}.json"

    body = "\n".join(json.dumps(e) for e in decoded_events)

    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=key,
        Body=body.encode("utf-8"),
        ContentType="application/json",
    )

    print(f"Wrote {len(decoded_events)} events to s3://{TARGET_BUCKET}/{key}")
    return {"statusCode": 200, "processed": len(decoded_events), "key": key}