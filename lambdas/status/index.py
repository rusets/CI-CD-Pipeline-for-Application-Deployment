import os
import time
import json
import boto3

EC2 = boto3.client("ec2", region_name=os.environ.get("AWS_REGION", "us-east-1"))
INSTANCE_ID = os.environ.get("INSTANCE_ID")

def _describe_state(instance_id: str) -> dict:
    d = EC2.describe_instances(InstanceIds=[instance_id])
    inst = d["Reservations"][0]["Instances"][0]
    return {
        "ok": True,
        "instanceId": instance_id,
        "state": inst["State"]["Name"],
        "publicIp": inst.get("PublicIpAddress"),
        "publicDns": inst.get("PublicDnsName"),
        "now": int(time.time())
    }

def _wrap(event, payload: dict, status: int = 200):
    is_apigw = isinstance(event, dict) and (event.get("version") == "2.0" or "rawPath" in event)
    if is_apigw:
        return {
            "statusCode": status,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(payload)
        }
    return payload

def lambda_handler(event, context):
    if not INSTANCE_ID:
        return _wrap(event, {"ok": False, "error": "Missing INSTANCE_ID"}, 500)
    try:
        payload = _describe_state(INSTANCE_ID)
        return _wrap(event, payload, 200)
    except Exception as e:
        return _wrap(event, {"ok": False, "error": str(e)}, 500)