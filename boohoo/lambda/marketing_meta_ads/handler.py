import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_meta_ads
    
    for brand in config.BRAND_SOURCES:
        print(f"\n[{brand}] Generating meta ads...")
        meta_ads = gen_meta_ads(brand, ingest_date, ingest_time)
        keys.append(utils.upload(meta_ads, brand, "marketing", "meta_ads", ingest_date))

    return {"status": "success", "files": len(keys)}
