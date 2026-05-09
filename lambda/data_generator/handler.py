"""
Data Generator — Boohoo Group Multi-Brand Data Lake

S3 path: {brand}/{source}/{dataset}/history/ingest_date={date}/{dataset}.jsonl.gz

Each brand uses a different e-commerce platform with different schemas:
  boohoo/boohoo_man  → boohoo_commerce (custom platform)
  prettylittlething  → salesforce_commerce (SFCC)
  nastygal           → shopify
  karen_millen/coast → magento
  debenhams          → oracle_commerce
"""
import os, json, gzip, random
from datetime import datetime, timedelta, timezone
from typing import Any
import boto3

from config import (
    BRAND_SOURCES, PRODUCT_SCHEMAS, ORDER_SCHEMAS, CUSTOMER_SCHEMAS,
    CATEGORIES, COLOURS, MATERIALS, SIZES_NUMERIC, SIZES_ALPHA, SIZES_SHOES,
    FIRST_F, FIRST_M, LAST_NAMES, CITIES, STATUSES_MAP, PAYMENTS_MAP,
)

s3 = boto3.client("s3")
BUCKET = os.environ.get("BUCKET_NAME", "boohoo-dns-rdl-staging")
SEED = 42
random.seed(SEED)


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


def gen_products(brand, source, n, ingest_date, ingest_time):
    schema = PRODUCT_SCHEMAS[source]
    cats = list(CATEGORIES.keys())
    rows = []
    brand_upper = brand.replace("_", " ").title()
    premium = brand in ("karen_millen", "coast")

    for i in range(1, n + 1):
        cat = cats[(i - 1) % len(cats)]
        subcats = CATEGORIES[cat]
        subcat = random.choice(subcats)
        colour = random.choice(COLOURS)
        rrp = _price(cat)
        if premium:
            rrp = round(rrp * random.uniform(2.0, 3.5), 2)
        cost = round(rrp * random.uniform(0.18, 0.32), 2)
        cur = round(rrp * (1 - random.choice([0, 0, 0, 0.1, 0.2, 0.3, 0.4, 0.5])), 2)
        sizes = _sizes(cat)

        rec = {
            schema["id_field"]: f"{brand[:3].upper()}-{cat[:3].upper()}-{i:05d}",
            schema["name_field"]: f"{brand_upper} {colour} {_singular(subcat)}",
            schema["color_field"]: colour,
            schema["cat_field"]: cat,
            schema["subcat_field"]: subcat,
            schema["price_field"]: cur,
            schema["cost_field"]: cost,
            "rrp": rrp,
            "brand": brand_upper,
            "available_sizes": sizes,
            "is_active": random.random() > 0.08,
            "stock_status": random.choices(["in_stock", "low_stock", "out_of_stock"], [70, 20, 10])[0],
            "created_at": (datetime(2023,1,1)+timedelta(days=random.randint(0,800))).isoformat(),
            "updated_at": (datetime(2025,1,1)+timedelta(days=random.randint(0,200))).isoformat(),
            "ingest_date": ingest_date, "ingest_time": ingest_time,
        }
        # Source-specific extra fields
        extras = schema["extra_fields"]
        rec[extras[0]] = random.choice(MATERIALS)
        rec[extras[1]] = random.choice(["SS24","AW24","SS25","AW25"])
        rec[extras[2]] = f"SUP-{random.randint(1000,9999)}"
        rec[extras[3]] = round(random.uniform(0.1, 2.5), 2)
        rows.append(rec)
    return rows


def gen_customers(brand, source, n, ingest_date, ingest_time):
    schema = CUSTOMER_SCHEMAS[source]
    rows = []
    base = datetime(2023, 1, 1)

    for i in range(1, n + 1):
        female = random.random() < 0.70
        first = random.choice(FIRST_F if female else FIRST_M)
        last = random.choice(LAST_NAMES)
        city, country = random.choice(CITIES)
        signup = base + timedelta(days=int(random.betavariate(2, 5) * 1095))
        domains = ["gmail.com","outlook.com","yahoo.co.uk","hotmail.co.uk","icloud.com"]
        email = f"{first.lower()}.{last.lower()}{random.randint(1,99)}@{domains[i%len(domains)]}"

        rec = {
            schema["id_field"]: f"{brand[:3].upper()}-C-{i:05d}",
            schema["email_field"]: email,
            schema["first_field"]: first,
            schema["last_field"]: last,
            "ingest_date": ingest_date, "ingest_time": ingest_time,
        }
        extras = schema["extra_fields"]
        rec[extras[0]] = f"+44{random.randint(7000000000,7999999999)}"  # phone
        rec[extras[1]] = city
        rec[extras[2]] = country
        rec[extras[3]] = random.choice(["VIP","Frequent","Regular","Occasional","New"])  # segment
        rec[extras[4]] = signup.strftime("%Y-%m-%d")  # signup date
        if len(extras) > 5:
            rec[extras[5]] = "F" if female else "M"
        if len(extras) > 6:
            rec[extras[6]] = random.random() > 0.35
        if len(extras) > 7:
            rec[extras[7]] = random.randint(0, 50)
        rows.append(rec)
    return rows


def gen_orders(brand, source, n, n_cust, n_prod, ingest_date, ingest_time):
    o_schema = ORDER_SCHEMAS[source]
    statuses = STATUSES_MAP[source]
    payments = PAYMENTS_MAP[source]
    cats = list(CATEGORIES.keys())
    p_schema = PRODUCT_SCHEMAS[source]

    top = list(range(1, int(n_cust * 0.2) + 1))
    rest = list(range(int(n_cust * 0.2) + 1, n_cust + 1))
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days

    orders, items = [], []
    item_idx = 1

    for oi in range(1, n + 1):
        cust = random.choice(top) if random.random() < 0.80 else random.choice(rest)
        od = start + timedelta(days=random.randint(0, days))
        m = od.month
        if m == 11 and random.random() < 0.4:
            od = od.replace(day=random.randint(20, 30))
        elif m == 1 and random.random() < 0.3:
            od = od.replace(day=random.randint(1, 15))

        h = random.choices(range(24), weights=[1,1,1,1,1,2,3,5,7,8,8,7,8,8,7,6,5,6,8,9,10,8,5,3], k=1)[0]
        n_items = random.choices([1,2,3,4,5], weights=[25,35,25,10,5], k=1)[0]
        total, disc = 0.0, 0.0
        used = set()
        o_items = []

        for _ in range(n_items):
            pn = random.randint(1, n_prod)
            while pn in used: pn = random.randint(1, n_prod)
            used.add(pn)
            cat = cats[(pn-1) % len(cats)]
            size = random.choice(_sizes(cat))
            qty = random.choices([1,2,3], weights=[70,25,5], k=1)[0]
            up = _price(cat)
            dp = random.choices([0,10,15,20,25,30,40,50], weights=[35,10,10,15,10,10,7,3], k=1)[0]
            lt = round(qty * up * (1 - dp / 100), 2)
            total += lt
            disc += round(qty * up * dp / 100, 2)

            o_items.append({
                "order_item_id": f"{brand[:3].upper()}-LI-{item_idx:07d}",
                o_schema["id_field"]: f"{brand[:3].upper()}-O-{oi:06d}",
                p_schema["id_field"]: f"{brand[:3].upper()}-{cat[:3].upper()}-{pn:05d}",
                "quantity": qty,
                "unit_price": up,
                p_schema["size_field"]: size,
                "discount_pct": dp,
                "line_total": lt,
                "brand": brand.replace("_"," ").title(),
                "ingest_date": ingest_date, "ingest_time": ingest_time,
            })
            item_idx += 1

        shipping = 0.00 if total >= 30 else 3.99
        order = {
            o_schema["id_field"]: f"{brand[:3].upper()}-O-{oi:06d}",
            o_schema["cust_field"]: f"{brand[:3].upper()}-C-{cust:05d}",
            o_schema["date_field"]: od.strftime("%Y-%m-%dT%H:%M:%SZ").replace("00:00:00", f"{h:02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"),
            o_schema["total_field"]: round(total, 2),
            o_schema["status_field"]: random.choices(statuses, weights=[50,20,10,15,5], k=1)[0],
            o_schema["payment_field"]: random.choice(payments),
            "discount_amount": round(disc, 2),
            "shipping_cost": shipping,
            "item_count": n_items,
            "brand": brand.replace("_"," ").title(),
            "ingest_date": ingest_date, "ingest_time": ingest_time,
        }
        extras = o_schema["extra_fields"]
        order[extras[0]] = f"PROMO{random.randint(10,99)}" if random.random() < 0.35 else None
        order[extras[1]] = random.choice(["standard","express","next_day","click_collect"])
        order[extras[2]] = f"WH-{random.randint(1,5)}" if source != "shopify" else "web"

        orders.append(order)
        items.extend(o_items)

    return orders, items


def upload(records, brand, source, dataset, ingest_date):
    key = f"{brand}/{source}/{dataset}/history/ingest_date={ingest_date}/{dataset}.jsonl.gz"
    jsonl = "\n".join(json.dumps(r, default=str) for r in records)
    body = gzip.compress(jsonl.encode("utf-8"))
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType="application/gzip")
    print(f"  s3://{BUCKET}/{key} -> {len(records):,} records ({len(body):,} bytes)")
    return key


def lambda_handler(event: dict[str, Any] = {}, context: Any = None) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []
    counts = {}

    for brand, cfg in BRAND_SOURCES.items():
        src = cfg["source"]
        n_c, n_p, n_o = cfg["customers_per"], cfg["products_per"], cfg["orders_per"]
        print(f"\n[{brand}] source={src} | {n_c} customers, {n_p} products, {n_o} orders")

        customers = gen_customers(brand, src, n_c, ingest_date, ingest_time)
        products = gen_products(brand, src, n_p, ingest_date, ingest_time)
        orders, items = gen_orders(brand, src, n_o, n_c, n_p, ingest_date, ingest_time)

        keys.append(upload(customers, brand, src, "customers", ingest_date))
        keys.append(upload(products, brand, src, "products", ingest_date))
        keys.append(upload(orders, brand, src, "orders", ingest_date))
        keys.append(upload(items, brand, src, "order_items", ingest_date))

        counts[brand] = {"customers": len(customers), "products": len(products),
                         "orders": len(orders), "order_items": len(items)}

    result = {"status": "success", "ingest_date": ingest_date,
              "files": len(keys), "counts": counts}
    print(f"\n{json.dumps(result, indent=2)}")
    return result


if __name__ == "__main__":
    import os
    os.environ.setdefault("BUCKET_NAME", "boohoo-dns-rdl-staging")
    os.environ.setdefault("AWS_PROFILE", "playEngineer")
    os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")
    lambda_handler()
