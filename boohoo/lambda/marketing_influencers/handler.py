import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_influencer_posts
    
    for brand in config.BRAND_SOURCES:
        print(f"\n[{brand}] Generating influencer posts...")
        influencer = gen_influencer_posts(brand, ingest_date, ingest_time)
        keys.append(utils.upload(influencer, brand, "marketing", "influencer_posts", ingest_date))

    return {"status": "success", "files": len(keys)}
