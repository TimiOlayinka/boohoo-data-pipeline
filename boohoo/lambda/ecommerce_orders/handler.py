import json
from datetime import datetime, timezone
import config
import utils

def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    
    from handler_logic import gen_orders
    
    for brand, cfg in config.BRAND_SOURCES.items():
        src = cfg["source"]
        n_c, n_p, n_o = cfg["customers_per"], cfg["products_per"], cfg["orders_per"]
        print(f"\n[{brand}] Generating orders...")
        orders, items = gen_orders(brand, src, n_o, n_c, n_p, ingest_date, ingest_time)
        keys.append(utils.upload(orders, brand, src, "orders", ingest_date))
        keys.append(utils.upload(items, brand, src, "order_items", ingest_date))

    return {"status": "success", "files": len(keys)}
