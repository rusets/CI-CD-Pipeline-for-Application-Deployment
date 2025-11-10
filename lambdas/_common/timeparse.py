import time, datetime

def parse_ts(value: str) -> int:
    try:
        return int(value)
    except Exception:
        pass
    try:
        return int(datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp())
    except Exception:
        pass
    return 0

def now_ts() -> int:
    return int(time.time())
