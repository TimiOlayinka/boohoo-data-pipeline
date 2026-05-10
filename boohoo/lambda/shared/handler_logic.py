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
    BRAND_MARKETING_BUDGETS,
    META_ADS_OBJECTIVES, META_ADS_PUBLISHER_PLATFORMS, META_ADS_CAMPAIGN_TEMPLATES,
    GOOGLE_ADS_CHANNEL_TYPES, GOOGLE_ADS_DEVICES, GOOGLE_ADS_NETWORK_TYPES, GOOGLE_ADS_CAMPAIGN_TEMPLATES,
    TIKTOK_ADS_OBJECTIVES, TIKTOK_ADS_CAMPAIGN_TEMPLATES,
    GA4_TRAFFIC_SOURCES, GA4_TRAFFIC_WEIGHTS, GA4_DEVICES, GA4_DEVICE_WEIGHTS, GA4_LANDING_PAGES,
    EMAIL_CAMPAIGN_TYPES, EMAIL_CAMPAIGN_TEMPLATES, EMAIL_SUBJECT_LINES,
    INFLUENCER_TIERS, INFLUENCER_PLATFORMS, INFLUENCER_PLATFORM_WEIGHTS,
    INFLUENCER_CONTENT_TYPES, INFLUENCER_NAMES,
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


# ══════════════════════════════════════════════════════════════════════════════
# MARKETING DATA GENERATORS
# ══════════════════════════════════════════════════════════════════════════════

def _seasonal_multiplier(date_obj):
    """Simulate realistic fashion e-commerce seasonality."""
    m, d = date_obj.month, date_obj.day
    if m == 11 and d >= 20:    return random.uniform(2.5, 4.0)   # Black Friday
    if m == 12 and d <= 20:    return random.uniform(1.8, 2.5)   # Christmas
    if m == 1 and d <= 15:     return random.uniform(1.5, 2.0)   # January Sale
    if m == 6:                 return random.uniform(1.2, 1.5)   # Summer Sale
    if m in (3, 9):            return random.uniform(1.1, 1.3)   # New Season Launch
    if m == 2 and d >= 10:     return random.uniform(1.1, 1.4)   # Valentine's
    return random.uniform(0.7, 1.1)


def _day_of_week_factor(date_obj):
    """Weekday spend varies — higher on Mon-Wed (campaign launches), lower weekends."""
    dow = date_obj.weekday()
    factors = [1.1, 1.15, 1.1, 1.0, 0.95, 0.85, 0.85]
    return factors[dow]


def gen_meta_ads(brand, ingest_date, ingest_time):
    """Generate Meta Ads campaign insights — daily performance per campaign × platform."""
    brand_title = brand.replace("_", " ").title()
    budget = BRAND_MARKETING_BUDGETS.get(brand, {}).get("meta", 10000)
    campaigns = META_ADS_CAMPAIGN_TEMPLATES[:random.randint(5, 8)]
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    rows = []

    for campaign_tpl in campaigns:
        campaign_name = campaign_tpl.format(brand=brand_title.replace(" ", ""))
        campaign_id = f"META-{abs(hash(campaign_name)) % 10**12}"
        objective = random.choice(META_ADS_OBJECTIVES)
        daily_budget = budget / 7 / len(campaigns)  # weekly → daily per campaign

        for day_offset in range(0, days, random.randint(1, 3)):  # not every day
            d = start + timedelta(days=day_offset)
            mult = _seasonal_multiplier(d) * _day_of_week_factor(d)
            spend = round(daily_budget * mult * random.uniform(0.6, 1.4), 2)

            for platform in random.sample(META_ADS_PUBLISHER_PLATFORMS, random.randint(1, 3)):
                plat_share = {"facebook": 0.45, "instagram": 0.45, "audience_network": 0.10}
                plat_spend = round(spend * plat_share.get(platform, 0.33) * random.uniform(0.8, 1.2), 2)
                impressions = int(plat_spend / random.uniform(3, 12) * 1000)
                clicks = int(impressions * random.uniform(0.008, 0.035))
                reach = int(impressions * random.uniform(0.55, 0.85))

                rows.append({
                    "campaign_id": campaign_id,
                    "campaign_name": campaign_name,
                    "objective": objective,
                    "account_id": f"act_{abs(hash(brand)) % 10**10}",
                    "publisher_platform": platform,
                    "date_start": d.strftime("%Y-%m-%d"),
                    "spend": plat_spend,
                    "impressions": impressions,
                    "clicks": max(clicks, 1),
                    "reach": reach,
                    "frequency": round(impressions / max(reach, 1), 2),
                    "cpc": round(plat_spend / max(clicks, 1), 2),
                    "cpm": round(plat_spend / max(impressions, 1) * 1000, 2),
                    "ctr": round(clicks / max(impressions, 1) * 100, 4),
                    "outbound_clicks": int(clicks * random.uniform(0.6, 0.9)),
                    "outbound_clicks_ctr": round(clicks * random.uniform(0.6, 0.9) / max(impressions, 1) * 100, 4),
                    "video_p25_watched": int(impressions * random.uniform(0.3, 0.6)) if objective == "OUTCOME_AWARENESS" else 0,
                    "video_p50_watched": int(impressions * random.uniform(0.15, 0.35)) if objective == "OUTCOME_AWARENESS" else 0,
                    "video_p75_watched": int(impressions * random.uniform(0.08, 0.20)) if objective == "OUTCOME_AWARENESS" else 0,
                    "video_p100_watched": int(impressions * random.uniform(0.03, 0.12)) if objective == "OUTCOME_AWARENESS" else 0,
                    "brand": brand_title,
                    "ingest_date": ingest_date, "ingest_time": ingest_time,
                })
    return rows


def gen_google_ads(brand, ingest_date, ingest_time):
    """Generate Google Ads campaign performance — daily ad-level data with device breakdown."""
    brand_title = brand.replace("_", " ").title()
    budget = BRAND_MARKETING_BUDGETS.get(brand, {}).get("google", 10000)
    campaigns = GOOGLE_ADS_CAMPAIGN_TEMPLATES[:random.randint(5, 8)]
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    rows = []
    customer_id = f"GAD-{abs(hash(brand)) % 10**10}"

    for campaign_tpl in campaigns:
        campaign_name = campaign_tpl.format(brand=brand_title.replace(" ", ""))
        campaign_id = f"{abs(hash(campaign_name)) % 10**10}"
        channel_type = random.choice(GOOGLE_ADS_CHANNEL_TYPES)
        daily_budget = budget / 7 / len(campaigns)

        for day_offset in range(0, days, random.randint(1, 2)):
            d = start + timedelta(days=day_offset)
            mult = _seasonal_multiplier(d) * _day_of_week_factor(d)

            for device in GOOGLE_ADS_DEVICES:
                dev_share = {"MOBILE": 0.55, "DESKTOP": 0.35, "TABLET": 0.10}
                dev_spend = round(daily_budget * mult * dev_share[device] * random.uniform(0.5, 1.5), 2)
                cost_micros = int(dev_spend * 1_000_000)
                impressions = int(dev_spend / random.uniform(2, 15) * 1000)
                clicks = int(impressions * random.uniform(0.02, 0.08))
                conv_rate = random.uniform(0.01, 0.06)
                conversions = round(clicks * conv_rate, 2)
                avg_order = random.uniform(25, 80) if brand not in ("karen_millen", "coast") else random.uniform(60, 180)

                rows.append({
                    "customer_id": customer_id,
                    "customer_name": f"{brand_title} | UK",
                    "campaign_id": campaign_id,
                    "campaign_name": campaign_name,
                    "campaign_status": random.choices(["ENABLED", "PAUSED", "REMOVED"], [85, 10, 5])[0],
                    "channel_type": channel_type,
                    "ad_group_id": f"AG-{abs(hash(campaign_name + device)) % 10**8}",
                    "ad_id": f"AD-{abs(hash(campaign_name + device + str(day_offset))) % 10**10}",
                    "date_day": d.strftime("%Y-%m-%d"),
                    "device": device,
                    "ad_network_type": random.choice(GOOGLE_ADS_NETWORK_TYPES[:3]),
                    "cost_micros": cost_micros,
                    "spend": dev_spend,
                    "impressions": impressions,
                    "clicks": max(clicks, 1),
                    "interactions": max(clicks, 1),
                    "conversions": conversions,
                    "conversions_value": round(conversions * avg_order, 2),
                    "all_conversions": round(conversions * random.uniform(1.0, 1.3), 2),
                    "all_conversions_value": round(conversions * avg_order * random.uniform(1.0, 1.3), 2),
                    "video_quartile_p25_rate": round(random.uniform(0.4, 0.7), 2) if channel_type == "VIDEO" else 0,
                    "video_quartile_p50_rate": round(random.uniform(0.2, 0.5), 2) if channel_type == "VIDEO" else 0,
                    "video_quartile_p75_rate": round(random.uniform(0.1, 0.3), 2) if channel_type == "VIDEO" else 0,
                    "video_quartile_p100_rate": round(random.uniform(0.05, 0.15), 2) if channel_type == "VIDEO" else 0,
                    "brand": brand_title,
                    "ingest_date": ingest_date, "ingest_time": ingest_time,
                })
    return rows


def gen_tiktok_ads(brand, ingest_date, ingest_time):
    """Generate TikTok Ads insights — daily ad-level data with video engagement metrics."""
    brand_title = brand.replace("_", " ").title()
    budget = BRAND_MARKETING_BUDGETS.get(brand, {}).get("tiktok", 5000)
    campaigns = TIKTOK_ADS_CAMPAIGN_TEMPLATES[:random.randint(4, 6)]
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    rows = []
    advertiser_id = f"TT-{abs(hash(brand)) % 10**10}"

    for campaign_tpl in campaigns:
        campaign_name = campaign_tpl.format(brand=brand_title.replace(" ", ""))
        ad_id = f"TT-AD-{abs(hash(campaign_name)) % 10**12}"
        objective = random.choice(TIKTOK_ADS_OBJECTIVES)
        daily_budget = budget / 7 / len(campaigns)

        for day_offset in range(0, days, random.randint(1, 3)):
            d = start + timedelta(days=day_offset)
            mult = _seasonal_multiplier(d) * _day_of_week_factor(d)
            spend = round(daily_budget * mult * random.uniform(0.5, 1.5), 2)
            impressions = int(spend / random.uniform(2, 8) * 1000)
            clicks = int(impressions * random.uniform(0.005, 0.025))
            reach = int(impressions * random.uniform(0.5, 0.8))
            conv_rate = random.uniform(0.005, 0.03)
            conversions = int(clicks * conv_rate)

            rows.append({
                "advertiser_id": advertiser_id,
                "ad_id": ad_id + f"-{day_offset}",
                "campaign_name": campaign_name,
                "objective": objective,
                "stat_time_day": d.strftime("%Y-%m-%d"),
                "spend": spend,
                "impressions": impressions,
                "clicks": max(clicks, 1),
                "reach": reach,
                "frequency": round(impressions / max(reach, 1), 2),
                "ctr": round(clicks / max(impressions, 1) * 100, 4),
                "cpc": round(spend / max(clicks, 1), 2),
                "cpm": round(spend / max(impressions, 1) * 1000, 2),
                "conversion_rate": round(conv_rate * 100, 4),
                "conversion": conversions,
                "cost_per_conversion": round(spend / max(conversions, 1), 2),
                "purchase": int(conversions * random.uniform(0.3, 0.7)),
                "video_play_actions": int(impressions * random.uniform(0.6, 0.9)),
                "video_watched_2s": int(impressions * random.uniform(0.4, 0.7)),
                "video_watched_6s": int(impressions * random.uniform(0.2, 0.5)),
                "video_views_p25": int(impressions * random.uniform(0.3, 0.55)),
                "video_views_p50": int(impressions * random.uniform(0.15, 0.35)),
                "video_views_p75": int(impressions * random.uniform(0.08, 0.2)),
                "video_views_p100": int(impressions * random.uniform(0.03, 0.12)),
                "brand": brand_title,
                "ingest_date": ingest_date, "ingest_time": ingest_time,
            })
    return rows


def gen_ga4_sessions(brand, n_sessions, ingest_date, ingest_time):
    """Generate GA4 web session data — traffic sources, devices, conversions, revenue."""
    brand_title = brand.replace("_", " ").title()
    cats = list(CATEGORIES.keys())
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    rows = []
    premium = brand in ("karen_millen", "coast")

    for i in range(1, n_sessions + 1):
        d = start + timedelta(days=random.randint(0, days))
        mult = _seasonal_multiplier(d)
        source, medium, channel_group = random.choices(GA4_TRAFFIC_SOURCES, weights=GA4_TRAFFIC_WEIGHTS)[0]
        device = random.choices(GA4_DEVICES, weights=GA4_DEVICE_WEIGHTS)[0]
        cat = random.choice(cats)
        landing = random.choice(GA4_LANDING_PAGES).format(cat=cat.lower(), product_id=f"{brand[:3].upper()}-{i:05d}")

        # Session behaviour
        page_views = random.choices([1, 2, 3, 4, 5, 6, 7, 8, 10, 15], weights=[15, 20, 20, 15, 10, 8, 5, 3, 2, 2])[0]
        is_bounced = page_views == 1 and random.random() < 0.65
        session_duration = 0 if is_bounced else int(page_views * random.uniform(15, 45))
        engaged = not is_bounced and session_duration > 10

        # Conversions (higher for paid, lower for direct/organic)
        conv_boost = {"Paid Search": 1.4, "Paid Social": 1.1, "Paid Shopping": 1.6, "Email": 1.8}
        base_conv = 0.025 * mult * conv_boost.get(channel_group, 1.0)
        purchased = random.random() < base_conv and engaged
        avg_order = random.uniform(30, 70) if not premium else random.uniform(70, 200)
        revenue = round(avg_order * random.uniform(0.8, 1.5), 2) if purchased else 0

        # UTM params (link back to ad campaigns)
        utm_campaign = None
        if medium == "cpc" and source in ("google", "bing"):
            utm_campaign = random.choice(GOOGLE_ADS_CAMPAIGN_TEMPLATES).format(brand=brand_title.replace(" ", ""))
        elif medium == "cpc" and source in ("facebook", "instagram"):
            utm_campaign = random.choice(META_ADS_CAMPAIGN_TEMPLATES).format(brand=brand_title.replace(" ", ""))
        elif medium == "cpc" and source == "tiktok":
            utm_campaign = random.choice(TIKTOK_ADS_CAMPAIGN_TEMPLATES).format(brand=brand_title.replace(" ", ""))

        h = random.choices(range(24), weights=[1,1,1,1,1,2,3,5,7,8,8,7,8,8,7,6,5,6,8,9,10,8,5,3], k=1)[0]

        rows.append({
            "session_id": f"GA4-{brand[:3].upper()}-{d.strftime('%Y%m%d')}-{i:07d}",
            "user_pseudo_id": f"USR-{brand[:3].upper()}-{random.randint(1, n_sessions // 3):06d}",
            "session_date": d.strftime("%Y-%m-%d"),
            "session_timestamp": d.strftime(f"%Y-%m-%dT{h:02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}Z"),
            "source": source,
            "medium": medium,
            "channel_group": channel_group,
            "utm_campaign": utm_campaign,
            "device_category": device,
            "country": random.choices(["United Kingdom", "Ireland", "United States", "France", "Germany", "Netherlands"],
                                       weights=[65, 8, 10, 5, 5, 7])[0],
            "landing_page": landing,
            "page_views": page_views,
            "session_duration_seconds": session_duration,
            "is_bounced": is_bounced,
            "is_engaged_session": engaged,
            "is_new_user": random.random() < 0.45,
            "transactions": 1 if purchased else 0,
            "revenue": revenue,
            "add_to_carts": 1 if (purchased or (engaged and random.random() < 0.12)) else 0,
            "checkouts": 1 if purchased else 0,
            "brand": brand_title,
            "ingest_date": ingest_date, "ingest_time": ingest_time,
        })
    return rows


def gen_email_campaigns(brand, ingest_date, ingest_time):
    """Generate email campaign performance — send-level aggregates per campaign."""
    brand_title = brand.replace("_", " ").title()
    budget = BRAND_MARKETING_BUDGETS.get(brand, {}).get("email", 1000)
    n_customers = BRAND_SOURCES[brand]["customers_per"]
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    cats = list(CATEGORIES.keys())
    rows = []

    # Generate campaigns spread across the date range
    for week_offset in range(0, days, 7):
        d = start + timedelta(days=week_offset)
        # 2-4 campaigns per week
        n_campaigns = random.randint(2, 4)
        for _ in range(n_campaigns):
            send_date = d + timedelta(days=random.randint(0, 6))
            if send_date > end:
                continue
            campaign_type = random.choice(EMAIL_CAMPAIGN_TYPES)
            cat = random.choice(cats)
            tpl = random.choice(EMAIL_CAMPAIGN_TEMPLATES)
            campaign_name = tpl.format(brand=brand_title.replace(" ", ""), date=send_date.strftime("%Y%m%d"), cat=cat)
            subject = random.choice(EMAIL_SUBJECT_LINES).format(brand=brand_title, cat=cat)
            mult = _seasonal_multiplier(send_date)

            # List size varies by campaign type
            list_sizes = {"promotional": 0.7, "abandoned_cart": 0.05, "welcome_series": 0.03,
                          "win_back": 0.15, "vip_exclusive": 0.08, "new_arrivals": 0.5,
                          "sale_announcement": 0.8, "birthday": 0.02, "post_purchase": 0.1}
            list_pct = list_sizes.get(campaign_type, 0.3)
            sent = int(n_customers * list_pct * random.uniform(0.8, 1.2))

            delivered = int(sent * random.uniform(0.95, 0.99))
            open_rate = random.uniform(0.15, 0.45) * (1.3 if campaign_type == "abandoned_cart" else 1.0)
            opened = int(delivered * min(open_rate, 0.65))
            click_rate = random.uniform(0.02, 0.08) * (1.5 if campaign_type == "abandoned_cart" else 1.0)
            clicked = int(delivered * min(click_rate, 0.15))
            unsubscribed = int(delivered * random.uniform(0.0005, 0.003))
            conv_rate = random.uniform(0.005, 0.025) * mult
            converted = int(clicked * conv_rate * 10)  # of those who clicked
            avg_order = random.uniform(30, 70) if brand not in ("karen_millen", "coast") else random.uniform(70, 180)
            revenue = round(converted * avg_order * random.uniform(0.8, 1.3), 2)

            rows.append({
                "campaign_id": f"EM-{abs(hash(campaign_name)) % 10**10}",
                "campaign_name": campaign_name,
                "campaign_type": campaign_type,
                "subject_line": subject,
                "send_date": send_date.strftime("%Y-%m-%d"),
                "send_timestamp": send_date.strftime(f"%Y-%m-%dT{random.choice([8,9,10,11,12]):02d}:00:00Z"),
                "list_size": sent,
                "delivered": delivered,
                "opened": opened,
                "unique_opens": int(opened * random.uniform(0.7, 0.9)),
                "clicked": clicked,
                "unique_clicks": int(clicked * random.uniform(0.6, 0.85)),
                "unsubscribed": unsubscribed,
                "bounced": sent - delivered,
                "spam_complaints": int(delivered * random.uniform(0.0001, 0.0005)),
                "converted": converted,
                "revenue": revenue,
                "open_rate": round(opened / max(delivered, 1) * 100, 2),
                "click_rate": round(clicked / max(delivered, 1) * 100, 2),
                "click_to_open_rate": round(clicked / max(opened, 1) * 100, 2),
                "conversion_rate": round(converted / max(clicked, 1) * 100, 2),
                "revenue_per_email": round(revenue / max(delivered, 1), 4),
                "brand": brand_title,
                "ingest_date": ingest_date, "ingest_time": ingest_time,
            })
    return rows


def gen_influencer_posts(brand, ingest_date, ingest_time):
    """Generate influencer post performance — per-post creator data with engagement."""
    brand_title = brand.replace("_", " ").title()
    budget = BRAND_MARKETING_BUDGETS.get(brand, {}).get("influencer", 3000)
    start, end = datetime(2024, 1, 1), datetime(2025, 12, 31)
    days = (end - start).days
    cats = list(CATEGORIES.keys())
    rows = []
    # Distribute budget across posts
    n_posts = int(budget / 200)  # ~avg cost per post

    for i in range(1, n_posts * 24 + 1):  # ~24 months of content
        d = start + timedelta(days=random.randint(0, days))
        tier_name = random.choices(list(INFLUENCER_TIERS.keys()),
                                    weights=[t["weight"] for t in INFLUENCER_TIERS.values()])[0]
        tier = INFLUENCER_TIERS[tier_name]
        platform = random.choices(INFLUENCER_PLATFORMS, weights=INFLUENCER_PLATFORM_WEIGHTS)[0]
        creator = random.choice(INFLUENCER_NAMES)
        followers = random.randint(*tier["followers_range"])
        cost = round(random.uniform(*tier["cost_range"]), 2)
        content_type = random.choice(INFLUENCER_CONTENT_TYPES)
        cat = random.choice(cats)

        # Engagement varies by tier (micro/nano have higher rates)
        eng_rates = {"Mega": (0.01, 0.03), "Macro": (0.02, 0.05), "Micro": (0.04, 0.10), "Nano": (0.06, 0.15)}
        eng_rate = random.uniform(*eng_rates[tier_name])
        reach = int(followers * random.uniform(0.15, 0.45))
        impressions = int(reach * random.uniform(1.1, 2.0))
        likes = int(impressions * eng_rate * random.uniform(0.6, 0.9))
        comments = int(likes * random.uniform(0.02, 0.08))
        shares = int(likes * random.uniform(0.01, 0.05))
        saves = int(likes * random.uniform(0.05, 0.15))
        link_clicks = int(impressions * random.uniform(0.005, 0.025))
        conversions = int(link_clicks * random.uniform(0.02, 0.08))
        avg_order = random.uniform(30, 70) if brand not in ("karen_millen", "coast") else random.uniform(70, 180)

        promo_code = f"{creator.upper()[:8]}{random.randint(10, 30)}"
        tracking_url = f"https://{brand.replace('_', '')}.com/?utm_source=influencer&utm_medium={platform.lower()}&utm_campaign={promo_code}"

        rows.append({
            "post_id": f"INF-{brand[:3].upper()}-{i:06d}",
            "creator_handle": f"@{creator}",
            "creator_name": creator,
            "creator_tier": tier_name,
            "creator_followers": followers,
            "platform": platform,
            "content_type": content_type,
            "post_date": d.strftime("%Y-%m-%d"),
            "post_url": f"https://{platform.lower()}.com/{creator}/post/{abs(hash(str(i))) % 10**12}",
            "category_promoted": cat,
            "promo_code": promo_code,
            "tracking_url": tracking_url,
            "cost": cost,
            "reach": reach,
            "impressions": impressions,
            "likes": likes,
            "comments": comments,
            "shares": shares,
            "saves": saves,
            "total_engagement": likes + comments + shares + saves,
            "engagement_rate": round((likes + comments + shares + saves) / max(impressions, 1) * 100, 4),
            "link_clicks": link_clicks,
            "conversions": conversions,
            "revenue_attributed": round(conversions * avg_order, 2),
            "emv": round((likes * 0.10 + comments * 0.50 + shares * 1.00 + saves * 0.30), 2),  # Earned Media Value
            "brand": brand_title,
            "ingest_date": ingest_date, "ingest_time": ingest_time,
        })
    return rows


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

    # ── Marketing Data Generation ─────────────────────────────────────────
    marketing_counts = {}
    for brand in BRAND_SOURCES:
        print(f"\n[{brand}] Generating marketing data...")

        meta_ads = gen_meta_ads(brand, ingest_date, ingest_time)
        google_ads = gen_google_ads(brand, ingest_date, ingest_time)
        tiktok_ads = gen_tiktok_ads(brand, ingest_date, ingest_time)
        ga4_sessions = gen_ga4_sessions(brand, BRAND_SOURCES[brand]["customers_per"] * 3, ingest_date, ingest_time)
        email = gen_email_campaigns(brand, ingest_date, ingest_time)
        influencer = gen_influencer_posts(brand, ingest_date, ingest_time)

        keys.append(upload(meta_ads, brand, "marketing", "meta_ads", ingest_date))
        keys.append(upload(google_ads, brand, "marketing", "google_ads", ingest_date))
        keys.append(upload(tiktok_ads, brand, "marketing", "tiktok_ads", ingest_date))
        keys.append(upload(ga4_sessions, brand, "marketing", "ga4_sessions", ingest_date))
        keys.append(upload(email, brand, "marketing", "email_campaigns", ingest_date))
        keys.append(upload(influencer, brand, "marketing", "influencer_posts", ingest_date))

        marketing_counts[brand] = {
            "meta_ads": len(meta_ads), "google_ads": len(google_ads),
            "tiktok_ads": len(tiktok_ads), "ga4_sessions": len(ga4_sessions),
            "email_campaigns": len(email), "influencer_posts": len(influencer),
        }
        print(f"  Marketing: {sum(marketing_counts[brand].values()):,} records")

    result = {"status": "success", "ingest_date": ingest_date,
              "files": len(keys), "counts": counts,
              "marketing_counts": marketing_counts}
    print(f"\n{json.dumps(result, indent=2)}")
    return result


if __name__ == "__main__":
    import os
    os.environ.setdefault("BUCKET_NAME", "boohoo-dns-rdl-staging")
    os.environ.setdefault("AWS_PROFILE", "playEngineer")
    os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")
    lambda_handler()
