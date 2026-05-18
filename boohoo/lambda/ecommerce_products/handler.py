import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_products
    
    for brand, cfg in config.BRAND_SOURCES.items():
        src = cfg["source"]
        n_p = cfg["products_per"]
        print(f"\n[{brand}] Generating products...")
        products = gen_products(brand, src, n_p, ingest_date, ingest_time)
        keys.append(utils.upload(products, brand, src, "products", ingest_date))

    return {"status": "success", "files": len(keys)}
