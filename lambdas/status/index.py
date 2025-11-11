import os
import time
import json
import boto3
from botocore.exceptions import ClientError

AWS_REGION = os.environ.get("AWS_REGION", "us-east-1").strip() or "us-east-1"
INSTANCE_ID = (os.environ.get("INSTANCE_ID") or "").strip()

ec2 = boto3.client("ec2", region_name=AWS_REGION)

def _wrap(event, payload, status=200):
    is_apigw = isinstance(event, dict) and (event.get("version") == "2.0" or "rawPath" in event)
    return {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": json.dumps(payload)} if is_apigw else payload

def _describe(instance_id):
    try:
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        resv = resp.get("Reservations", [])
        insts = resv and resv[0].get("Instances", [])
        if not insts:
            return None, "Instance not found"
        inst = insts[0]
        state = (inst.get("State") or {}).get("Name", "unknown")
        return {
            "ok": True,
            "instanceId": instance_id,
            "state": state,
            "publicIp": inst.get("PublicIpAddress") or "",
            "publicDns": inst.get("PublicDnsName") or "",
            "now": int(time.time())
        }, None
    except ClientError as e:
        return None, e.response.get("Error", {}).get("Message", str(e))
    except Exception as e:
        return None, str(e)

def lambda_handler(event, context):
    if not INSTANCE_ID:
        return _wrap(event, {"ok": False, "error": "Missing INSTANCE_ID"}, 500)
    payload, err = _describe(INSTANCE_ID)
    if err:
        return _wrap(event, {"ok": False, "error": err}, 500)
    return _wrap(event, payload, 200)