"""
s3_sync.py
==========
Downloads latest Parquet files from S3 to a local cache
directory for DuckDB to read. Run this before starting
the dashboard apps if not using S3 directly.
"""
import boto3
import os
from datetime import datetime

S3_BUCKET = os.environ.get("PARQUET_BUCKET", "boohoo-data-quality-staging")
S3_REGION = os.environ.get("AWS_REGION", "eu-west-2")
LOCAL_CACHE = os.environ.get("PARQUET_CACHE", os.path.join(os.path.dirname(__file__), "..", ".cache"))

LAYERS = {
    "rdl": [
        "boohoo_orders", "boohoo_customers", "boohoo_products",
        "boohoo_man_orders", "boohoo_man_customers", "boohoo_man_products",
        "plt_orders", "plt_customers", "plt_products",
        "nastygal_orders", "nastygal_customers", "nastygal_products",
        "karen_millen_orders", "karen_millen_customers", "karen_millen_products",
        "coast_orders", "coast_customers", "coast_products",
        "debenhams_orders", "debenhams_customers", "debenhams_products",
        "rdl_meta_ads", "rdl_google_ads", "rdl_tiktok_ads",
        "rdl_ga4_sessions", "rdl_email_campaigns", "rdl_influencer_posts",
    ],
    "odl": [
        "dim_customers", "dim_products", "dim_time", "dim_campaigns", "dim_marketing_channels",
        "fact_orders", "fact_meta_campaign_insights", "fact_google_ads_performance",
        "fact_tiktok_ad_insights", "fact_ga4_sessions", "fact_email_engagement",
        "fact_influencer_performance", "map_brand", "map_utm_sources", "map_channel_grouping",
    ],
    "adl": [
        "fact_marketing_summary", "fact_funnel_metrics", "fact_marketing_roas",
        "fact_marketing_spend_daily", "fact_channel_performance", "fact_campaign_performance",
        "fact_daily_sales", "fact_revenue_by_brand", "fact_product_performance",
        "fact_customer_segments", "fact_email_performance", "fact_influencer_roi",
    ],
}


def sync_latest(layers: list[str] = None):
    """Download latest Parquet files from S3."""
    s3 = boto3.client("s3", region_name=S3_REGION)
    target_layers = layers or list(LAYERS.keys())

    for layer in target_layers:
        models = LAYERS.get(layer, [])
        for model in models:
            prefix = f"{layer}/{model}/"

            # List objects to find the latest date folder
            response = s3.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix, Delimiter="/")
            prefixes = response.get("CommonPrefixes", [])

            if not prefixes:
                print(f"  SKIP: No data for {layer}/{model}")
                continue

            # Get the latest date folder
            latest = sorted([p["Prefix"] for p in prefixes])[-1]

            # List Parquet files in the latest folder
            files = s3.list_objects_v2(Bucket=S3_BUCKET, Prefix=latest)
            for obj in files.get("Contents", []):
                key = obj["Key"]
                if not key.endswith(".parquet"):
                    continue

                local_path = os.path.join(LOCAL_CACHE, key)
                os.makedirs(os.path.dirname(local_path), exist_ok=True)

                s3.download_file(S3_BUCKET, key, local_path)
                print(f"  ✓ {key} → {local_path}")


if __name__ == "__main__":
    print(f"Syncing Parquet from s3://{S3_BUCKET}/ → {LOCAL_CACHE}/\n")
    sync_latest()
    print("\nSync complete.")
