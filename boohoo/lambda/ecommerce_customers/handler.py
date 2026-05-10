import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    # We copy the generation logic from the original handler
    from handler_logic import gen_customers
    
    for brand, cfg in config.BRAND_SOURCES.items():
        src = cfg["source"]
        n_c = cfg["customers_per"]
        print(f"\n[{brand}] Generating customers...")
        customers = gen_customers(brand, src, n_c, ingest_date, ingest_time)
        keys.append(utils.upload(customers, brand, src, "customers", ingest_date))

    return {"status": "success", "files": len(keys)}
