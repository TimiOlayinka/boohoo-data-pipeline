import os, json, gzip, random
import boto3
from config import SIZES_NUMERIC, SIZES_ALPHA, SIZES_SHOES

s3 = boto3.client("s3")
BUCKET = os.environ.get("BUCKET_NAME", "hnb-dns-rdl-staging")

def _singular(s):
    if s.endswith("ses"): return s[:-2]
    if s.endswith("ies"): return s[:-3] + "y"
    if s.endswith("s") and not s.endswith("ss"): return s[:-1]
    return s

def _price(cat):
    ranges = {"Dresses":(12,85),"Tops":(6,40),"Bottoms":(8,55),"Outerwear":(20,120),
              "Knitwear":(10,50),"Swimwear":(6,35),"Activewear":(8,45),
              "Shoes":(10,65),"Accessories":(3,30)}
    lo, hi = ranges.get(cat, (8, 45))
    return round(random.uniform(lo, hi), 2)

def _sizes(cat):
    if cat == "Shoes": return SIZES_SHOES
    if cat in ("Accessories",): return ["ONE SIZE"]
    return random.choice([SIZES_NUMERIC, SIZES_ALPHA])

def _seasonal_multiplier(date_obj):
    m, d = date_obj.month, date_obj.day
    if m == 11 and d >= 20:    return random.uniform(2.5, 4.0)
    if m == 12 and d <= 20:    return random.uniform(1.8, 2.5)
    if m == 1 and d <= 15:     return random.uniform(1.5, 2.0)
    if m == 6:                 return random.uniform(1.2, 1.5)
    if m in (3, 9):            return random.uniform(1.1, 1.3)
    if m == 2 and d >= 10:     return random.uniform(1.1, 1.4)
    return random.uniform(0.7, 1.1)

def _day_of_week_factor(date_obj):
    dow = date_obj.weekday()
    factors = [1.1, 1.15, 1.1, 1.0, 0.95, 0.85, 0.85]
    return factors[dow]

def upload(records, brand, source, dataset, ingest_date):
    if not records:
        return None
    key = f"{brand}/{source}/{dataset}/history/ingest_date={ingest_date}/{dataset}.jsonl.gz"
    jsonl = "\n".join(json.dumps(r, default=str) for r in records)
    body = gzip.compress(jsonl.encode("utf-8"))
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType="application/gzip")
    print(f"  s3://{BUCKET}/{key} -> {len(records):,} records ({len(body):,} bytes)")
    return key
