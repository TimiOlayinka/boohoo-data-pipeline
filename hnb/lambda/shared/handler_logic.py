"""
Data Generator — HNB Customer Experience & Supply Chain Multi-Brand Data Lake
"""
import os, json, gzip, random
from datetime import datetime, timedelta, timezone
from typing import Any
import boto3

from shared.config.core import HNB_SOURCES
from shared.config.cx import CX_SCHEMAS
from shared.config.supply_chain import SUPPLY_CHAIN_SCHEMAS

s3 = boto3.client("s3")
BUCKET = os.environ.get("BUCKET_NAME", "hnb-dns-rdl-staging")
SEED = 42
random.seed(SEED)

def upload(records, source, dataset, ingest_date):
    if not records:
        return None
    key = f"hnb/{source}/{dataset}/history/ingest_date={ingest_date}/{dataset}.jsonl.gz"
    jsonl = "\n".join(json.dumps(r, default=str) for r in records)
    body = gzip.compress(jsonl.encode("utf-8"))
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType="application/gzip")
    print(f"  s3://{BUCKET}/{key} -> {len(records):,} records")
    return key


def generate_mock_data(schema_def, count, source, ingest_date, ingest_time, prefix="ID"):
    """Generic mock data generator based on field names."""
    rows = []
    fields = schema_def["fields"]
    for i in range(1, count + 1):
        rec = {}
        for f in fields:
            if f.endswith("_id"):
                rec[f] = f"{prefix}-{random.randint(1000, 999999)}"
            elif "date" in f or "timestamp" in f or "created_at" in f or "updated_at" in f:
                rec[f] = (datetime(2025,1,1) + timedelta(days=random.randint(0, 100))).isoformat()
            elif "status" in f:
                rec[f] = random.choice(["Open", "Closed", "Pending", "In Transit", "Delivered", "Exception"])
            elif "score" in f:
                rec[f] = random.randint(1, 10)
            elif "amount" in f or "price" in f:
                rec[f] = round(random.uniform(10.0, 500.0), 2)
            elif "quantity" in f:
                rec[f] = random.randint(1, 5)
            elif "is_" in f:
                rec[f] = random.choice([True, False])
            else:
                rec[f] = f"Mock_{f}_{i}"
                
        rec["ingest_date"] = ingest_date
        rec["ingest_time"] = ingest_time
        rec["source_system"] = source
        rows.append(rec)
    return rows

def process_lambda(domain: str, event: dict[str, Any] = {}) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    counts = {}
    
    print(f"Running generation for domain: {domain}")

    if domain == "cx_tickets":
        src = HNB_SOURCES["zendesk"]
        n_tickets = src["tickets_per"]
        n_agents = src["agents_per"]
        
        # Tickets, Teams, Agents, Custom Fields, Interactions
        for ds in ["tickets", "agents", "teams", "ticket_custom_fields", "ticket_interactions"]:
            recs = generate_mock_data(CX_SCHEMAS[ds], n_tickets if ds != "agents" and ds != "teams" else n_agents, "zendesk", ingest_date, ingest_time, "ZK")
            keys.append(upload(recs, "zendesk", ds, ingest_date))
            counts[ds] = len(recs)
            
    elif domain == "cx_surveys":
        src = HNB_SOURCES["qualtrics"]
        n_surv = src["surveys_per"]
        for ds in ["blnx_survey", "nps_visitview"]:
            recs = generate_mock_data(CX_SCHEMAS[ds], n_surv, "qualtrics", ingest_date, ingest_time, "QT")
            keys.append(upload(recs, "qualtrics", ds, ingest_date))
            counts[ds] = len(recs)

    elif domain == "supply_chain_warehouse":
        src = HNB_SOURCES["manhattan"]
        n_wh = src["warehouse_updates_per"]
        for ds in ["warehouse_status", "basket_items"]:
            recs = generate_mock_data(SUPPLY_CHAIN_SCHEMAS[ds], n_wh, "manhattan", ingest_date, ingest_time, "MH")
            keys.append(upload(recs, "manhattan", ds, ingest_date))
            counts[ds] = len(recs)

    elif domain == "supply_chain_deliveries":
        src = HNB_SOURCES["metapack"]
        n_parcels = src["parcels_per"]
        for ds in ["parcel_events", "delivery_item", "delivery_order", "digital_refunds"]:
            recs = generate_mock_data(SUPPLY_CHAIN_SCHEMAS[ds], n_parcels, "metapack", ingest_date, ingest_time, "MP")
            keys.append(upload(recs, "metapack", ds, ingest_date))
            counts[ds] = len(recs)

    elif domain == "supply_chain_otif":
        src = HNB_SOURCES["hnb_commerce"]
        n_otif = 5000
        for ds in ["customer_otif", "customer_otif_cc", "postship_defect"]:
            recs = generate_mock_data(SUPPLY_CHAIN_SCHEMAS[ds], n_otif, "hnb_commerce", ingest_date, ingest_time, "HC")
            keys.append(upload(recs, "hnb_commerce", ds, ingest_date))
            counts[ds] = len(recs)

    result = {"status": "success", "domain": domain, "ingest_date": ingest_date, "files": len([k for k in keys if k]), "counts": counts}
    print(f"\n{json.dumps(result, indent=2)}")
    return result

def lambda_handler(event: dict[str, Any] = {}, context: Any = None) -> dict[str, Any]:
    # Fallback if directly invoked
    return process_lambda("cx_tickets", event)
