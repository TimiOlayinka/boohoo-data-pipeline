import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_google_ads
    
    for brand in config.BRAND_SOURCES:
        print(f"\n[{brand}] Generating google ads...")
        google_ads = gen_google_ads(brand, ingest_date, ingest_time)
        keys.append(utils.upload(google_ads, brand, "marketing", "google_ads", ingest_date))

    return {"status": "success", "files": len(keys)}
