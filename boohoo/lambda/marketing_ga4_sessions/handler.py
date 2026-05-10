import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_ga4_sessions
    
    for brand, cfg in config.BRAND_SOURCES.items():
        print(f"\n[{brand}] Generating GA4 sessions...")
        ga4_sessions = gen_ga4_sessions(brand, cfg["customers_per"] * 3, ingest_date, ingest_time)
        keys.append(utils.upload(ga4_sessions, brand, "marketing", "ga4_sessions", ingest_date))

    return {"status": "success", "files": len(keys)}
