"""COPY S3 data into Redshift raw _history tables.
Uses Redshift Data API + COPY with GZIP JSON 'auto' format.
"""
import boto3, time, os

os.environ.setdefault("AWS_PROFILE", "playEngineer")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

client = boto3.client("redshift-data")
WORKGROUP = "boohoo-workgroup"
DB = "boohoo_dwh"
BUCKET = "boohoo-dns-rdl-staging"
IAM_ROLE = "arn:aws:iam::332779204498:role/RedshiftS3ReadRole"

# Mapping: (s3_brand, s3_source, dataset) -> redshift schema.table
COPY_JOBS = [
    # boohoo_commerce
    ("boohoo",              "boohoo_commerce", "customers",   "rdl_boohoo_commerce.boohoo_customers_history"),
    ("boohoo",              "boohoo_commerce", "products",    "rdl_boohoo_commerce.boohoo_products_history"),
    ("boohoo",              "boohoo_commerce", "orders",      "rdl_boohoo_commerce.boohoo_orders_history"),
    ("boohoo",              "boohoo_commerce", "order_items", "rdl_boohoo_commerce.boohoo_order_items_history"),
    ("boohoo_man",          "boohoo_commerce", "customers",   "rdl_boohoo_commerce.boohoo_man_customers_history"),
    ("boohoo_man",          "boohoo_commerce", "products",    "rdl_boohoo_commerce.boohoo_man_products_history"),
    ("boohoo_man",          "boohoo_commerce", "orders",      "rdl_boohoo_commerce.boohoo_man_orders_history"),
    ("boohoo_man",          "boohoo_commerce", "order_items", "rdl_boohoo_commerce.boohoo_man_order_items_history"),
    # salesforce_commerce
    ("prettylittlething",   "salesforce_commerce", "customers",   "rdl_salesforce_commerce.plt_customers_history"),
    ("prettylittlething",   "salesforce_commerce", "products",    "rdl_salesforce_commerce.plt_products_history"),
    ("prettylittlething",   "salesforce_commerce", "orders",      "rdl_salesforce_commerce.plt_orders_history"),
    ("prettylittlething",   "salesforce_commerce", "order_items", "rdl_salesforce_commerce.plt_order_items_history"),
    # shopify
    ("nastygal",            "shopify", "customers",   "rdl_shopify.nastygal_customers_history"),
    ("nastygal",            "shopify", "products",    "rdl_shopify.nastygal_products_history"),
    ("nastygal",            "shopify", "orders",      "rdl_shopify.nastygal_orders_history"),
    ("nastygal",            "shopify", "order_items", "rdl_shopify.nastygal_order_items_history"),
    # magento
    ("karen_millen",        "magento", "customers",   "rdl_magento.karen_millen_customers_history"),
    ("karen_millen",        "magento", "products",    "rdl_magento.karen_millen_products_history"),
    ("karen_millen",        "magento", "orders",      "rdl_magento.karen_millen_orders_history"),
    ("karen_millen",        "magento", "order_items", "rdl_magento.karen_millen_order_items_history"),
    ("coast",               "magento", "customers",   "rdl_magento.coast_customers_history"),
    ("coast",               "magento", "products",    "rdl_magento.coast_products_history"),
    ("coast",               "magento", "orders",      "rdl_magento.coast_orders_history"),
    ("coast",               "magento", "order_items", "rdl_magento.coast_order_items_history"),
    # oracle_commerce
    ("debenhams",           "oracle_commerce", "customers",   "rdl_oracle_commerce.debenhams_customers_history"),
    ("debenhams",           "oracle_commerce", "products",    "rdl_oracle_commerce.debenhams_products_history"),
    ("debenhams",           "oracle_commerce", "orders",      "rdl_oracle_commerce.debenhams_orders_history"),
    ("debenhams",           "oracle_commerce", "order_items", "rdl_oracle_commerce.debenhams_order_items_history"),
]


def run_sql(sql, desc=""):
    resp = client.execute_statement(WorkgroupName=WORKGROUP, Database=DB, Sql=sql)
    stmt_id = resp["Id"]
    while True:
        time.sleep(2)
        status = client.describe_statement(Id=stmt_id)
        s = status["Status"]
        if s == "FINISHED":
            rows = status.get("ResultRows", 0)
            print(f"  [{desc}] OK - {rows} rows loaded")
            return True
        elif s in ("FAILED", "ABORTED"):
            err = status.get("Error", "unknown")
            print(f"  [{desc}] FAIL: {err}")
            return False


if __name__ == "__main__":
    success = 0
    fail = 0
    for brand, source, dataset, table in COPY_JOBS:
        s3_path = f"s3://{BUCKET}/{brand}/{source}/{dataset}/history/"
        copy_sql = f"""
            COPY {table}
            FROM '{s3_path}'
            IAM_ROLE '{IAM_ROLE}'
            FORMAT AS JSON 'auto'
            GZIP
            TIMEFORMAT 'auto'
            DATEFORMAT 'auto'
            ;
        """
        print(f"COPY {table} <- {s3_path}")
        if run_sql(copy_sql, table.split(".")[-1]):
            success += 1
        else:
            fail += 1

    print(f"\nDone: {success} OK, {fail} failed out of {len(COPY_JOBS)} jobs.")
