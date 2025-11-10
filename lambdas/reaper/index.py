import os, time, boto3

REGION = os.environ.get("AWS_REGION", "us-east-1")
INSTANCE_ID = os.environ["INSTANCE_ID"]
IDLE_MIN = int(os.environ.get("IDLE_MINUTES", "5"))
SSM_PARAM = os.environ["SSM_PARAM_LAST_WAKE"]

ec2 = boto3.client("ec2", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)

def lambda_handler(event, context):
    try:
        p = ssm.get_parameter(Name=SSM_PARAM)
        last = int(p["Parameter"]["Value"])
    except Exception as e:
        print(f"[WARN] last_wake not found: {e}")
        return {"ok": True, "skipped": "no-ssm-param"}

    now = int(time.time())
    idle = (now - last) // 60

    try:
        d = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
        state = d["Reservations"][0]["Instances"][0]["State"]["Name"]
    except Exception as e:
        print(f"[ERROR] describe: {e}")
        return {"ok": False, "error": str(e)}

    if state != "running":
        print(f"[INFO] state={state}, nothing to stop (idle={idle})")
        return {"ok": True, "state": state, "idle": idle}

    if idle >= IDLE_MIN:
        print(f"[INFO] idle for {idle} min (limit {IDLE_MIN}) -> stopping {INSTANCE_ID}")
        ec2.stop_instances(InstanceIds=[INSTANCE_ID])
        return {"ok": True, "action": "stop", "idle": idle}

    print(f"[INFO] active: idle={idle} < {IDLE_MIN}")
    return {"ok": True, "action": "noop", "idle": idle}