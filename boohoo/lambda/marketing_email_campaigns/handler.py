import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_email_campaigns
    
    for brand in config.BRAND_SOURCES:
        print(f"\n[{brand}] Generating email campaigns...")
        email = gen_email_campaigns(brand, ingest_date, ingest_time)
        keys.append(utils.upload(email, brand, "marketing", "email_campaigns", ingest_date))

    return {"status": "success", "files": len(keys)}
