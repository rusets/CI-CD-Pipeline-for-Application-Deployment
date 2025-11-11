import os
import time
import json
import boto3
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION", "us-east-1")
INSTANCE_ID = os.environ.get("INSTANCE_ID", "").strip()
SSM_PARAM = os.environ.get("SSM_PARAM_LAST_WAKE", "").strip()

def _to_int(v, default):
    try:
        return int(str(v).strip())
    except Exception:
        return default

IDLE_MIN = _to_int(os.environ.get("IDLE_MINUTES", 5), 5)

ec2 = boto3.client("ec2", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)

def _now_epoch():
    return int(time.time())

def _get_last_wake(param_name):
    try:
        resp = ssm.get_parameter(Name=param_name)
        return _to_int(resp["Parameter"]["Value"], 0), None
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        return None, code or str(e)
    except Exception as e:
        return None, str(e)

def _instance_state(instance_id):
    try:
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        res = resp.get("Reservations", [])
        ins = res and res[0].get("Instances", [])
        state = ins and ins[0].get("State", {}).get("Name", "unknown")
        return state or "unknown", None
    except ClientError as e:
        return None, e.response.get("Error", {}).get("Message", str(e))
    except Exception as e:
        return None, str(e)

def _stop_instance(instance_id):
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        return True, None
    except ClientError as e:
        return False, e.response.get("Error", {}).get("Message", str(e))
    except Exception as e:
        return False, str(e)

def lambda_handler(event, context):
    if not INSTANCE_ID or not SSM_PARAM:
        return {
            "ok": False,
            "error": "Missing required env vars",
            "missing": {
                "INSTANCE_ID": bool(INSTANCE_ID),
                "SSM_PARAM_LAST_WAKE": bool(SSM_PARAM),
            },
        }

    last_wake, err = _get_last_wake(SSM_PARAM)
    if err is not None:
        print(f"[reaper] no last_wake ({err})")
        return {"ok": True, "skipped": "no-ssm-param"}

    now = _now_epoch()
    idle_minutes = max(0, (now - last_wake) // 60)

    state, err = _instance_state(INSTANCE_ID)
    if err is not None:
        print(f"[reaper] describe error: {err}")
        return {"ok": False, "error": err}

    if state != "running":
        print(f"[reaper] state={state}, idle={idle_minutes}m → nothing to stop")
        return {"ok": True, "state": state, "idle": idle_minutes, "action": "noop"}

    if idle_minutes >= IDLE_MIN:
        ok, serr = _stop_instance(INSTANCE_ID)
        if ok:
            print(f"[reaper] stop initiated: {INSTANCE_ID}, idle={idle_minutes}m (≥ {IDLE_MIN})")
            return {"ok": True, "state": state, "idle": idle_minutes, "action": "stop"}
        else:
            print(f"[reaper] stop error: {serr}")
            return {"ok": False, "state": state, "idle": idle_minutes, "error": serr}

    print(f"[reaper] active: idle={idle_minutes}m < {IDLE_MIN}m")
    return {"ok": True, "state": state, "idle": idle_minutes, "action": "noop"}