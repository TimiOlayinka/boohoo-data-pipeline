"""Create raw _history tables in Redshift for COPY ingestion.
Run via: python scripts/create_raw_tables.py
"""
import boto3, time, os

os.environ.setdefault("AWS_PROFILE", "playEngineer")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

client = boto3.client("redshift-data")
WORKGROUP = "boohoo-workgroup"
DB = "boohoo_dwh"

# Each brand's raw _history table — fields match the generator output exactly
TABLES = {
    # ─── boohoo_commerce ───────────────────────────────────────────
    "rdl_boohoo_commerce.boohoo_customers_history": """
        customer_id VARCHAR(30), email VARCHAR(100), first_name VARCHAR(50), last_name VARCHAR(50),
        phone VARCHAR(20), city VARCHAR(50), country VARCHAR(50), segment VARCHAR(20),
        signup_date VARCHAR(20), gender VARCHAR(5), is_subscribed BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_man_customers_history": """
        customer_id VARCHAR(30), email VARCHAR(100), first_name VARCHAR(50), last_name VARCHAR(50),
        phone VARCHAR(20), city VARCHAR(50), country VARCHAR(50), segment VARCHAR(20),
        signup_date VARCHAR(20), gender VARCHAR(5), is_subscribed BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_products_history": """
        sku VARCHAR(30), product_name VARCHAR(200), colour VARCHAR(30), department VARCHAR(30),
        product_type VARCHAR(50), selling_price NUMERIC(10,2), cost_price NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        material VARCHAR(50), season_code VARCHAR(10), supplier_code VARCHAR(20), weight_kg NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_man_products_history": """
        sku VARCHAR(30), product_name VARCHAR(200), colour VARCHAR(30), department VARCHAR(30),
        product_type VARCHAR(50), selling_price NUMERIC(10,2), cost_price NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        material VARCHAR(50), season_code VARCHAR(10), supplier_code VARCHAR(20), weight_kg NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_orders_history": """
        order_id VARCHAR(30), customer_id VARCHAR(30), order_date VARCHAR(30),
        order_total NUMERIC(10,2), order_status VARCHAR(30), payment_method VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), promo_code VARCHAR(20), delivery_method VARCHAR(20), warehouse_id VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_man_orders_history": """
        order_id VARCHAR(30), customer_id VARCHAR(30), order_date VARCHAR(30),
        order_total NUMERIC(10,2), order_status VARCHAR(30), payment_method VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), promo_code VARCHAR(20), delivery_method VARCHAR(20), warehouse_id VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_order_items_history": """
        order_item_id VARCHAR(30), order_id VARCHAR(30), sku VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_boohoo_commerce.boohoo_man_order_items_history": """
        order_item_id VARCHAR(30), order_id VARCHAR(30), sku VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    # ─── salesforce_commerce ───────────────────────────────────────
    "rdl_salesforce_commerce.plt_customers_history": """
        customer_no VARCHAR(30), email VARCHAR(100), first_name VARCHAR(50), last_name VARCHAR(50),
        phone_home VARCHAR(20), city VARCHAR(50), country_code VARCHAR(50), customer_group VARCHAR(20),
        creation_date VARCHAR(20), gender VARCHAR(5), email_opt_in BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_salesforce_commerce.plt_products_history": """
        product_id VARCHAR(30), display_name VARCHAR(200), c_color VARCHAR(30), primary_category_id VARCHAR(30),
        classification_category VARCHAR(50), price_book_price NUMERIC(10,2), c_cost NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        c_fabric_composition VARCHAR(50), c_season VARCHAR(10), c_supplier_id VARCHAR(20), c_weight NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_salesforce_commerce.plt_orders_history": """
        order_no VARCHAR(30), customer_no VARCHAR(30), creation_date VARCHAR(30),
        order_total NUMERIC(10,2), status VARCHAR(30), payment_instrument VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), coupon_code VARCHAR(20), shipment_method_id VARCHAR(20), site_id VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_salesforce_commerce.plt_order_items_history": """
        order_item_id VARCHAR(30), order_no VARCHAR(30), product_id VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    # ─── shopify ───────────────────────────────────────────────────
    "rdl_shopify.nastygal_customers_history": """
        id VARCHAR(30), email VARCHAR(100), first_name VARCHAR(50), last_name VARCHAR(50),
        phone VARCHAR(20), city VARCHAR(50), country VARCHAR(50), tags VARCHAR(20),
        created_at VARCHAR(20), accepts_marketing BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_shopify.nastygal_products_history": """
        variant_id VARCHAR(30), title VARCHAR(200), option1 VARCHAR(30), product_type VARCHAR(30),
        tags VARCHAR(50), price NUMERIC(10,2), cost NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        vendor VARCHAR(50), collection VARCHAR(10), handle VARCHAR(20), grams NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_shopify.nastygal_orders_history": """
        id VARCHAR(30), customer_id VARCHAR(30), created_at VARCHAR(30),
        total_price NUMERIC(10,2), financial_status VARCHAR(30), gateway VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), discount_codes VARCHAR(20), fulfillment_status VARCHAR(20), source_name VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_shopify.nastygal_order_items_history": """
        order_item_id VARCHAR(30), id VARCHAR(30), variant_id VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    # ─── magento ───────────────────────────────────────────────────
    "rdl_magento.karen_millen_customers_history": """
        entity_id VARCHAR(30), email VARCHAR(100), firstname VARCHAR(50), lastname VARCHAR(50),
        telephone VARCHAR(20), city VARCHAR(50), country_id VARCHAR(50), group_id VARCHAR(20),
        created_at VARCHAR(20), gender VARCHAR(5), is_subscribed BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.karen_millen_products_history": """
        entity_id VARCHAR(30), name VARCHAR(200), color_attribute VARCHAR(30), category_name VARCHAR(30),
        subcategory_name VARCHAR(50), price NUMERIC(10,2), cost NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        manufacturer VARCHAR(50), season VARCHAR(10), meta_keyword VARCHAR(20), weight NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.karen_millen_orders_history": """
        increment_id VARCHAR(30), customer_id VARCHAR(30), created_at VARCHAR(30),
        grand_total NUMERIC(10,2), status VARCHAR(30), payment_method VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), coupon_code VARCHAR(20), shipping_method VARCHAR(20), store_id VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.karen_millen_order_items_history": """
        order_item_id VARCHAR(30), increment_id VARCHAR(30), entity_id VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.coast_customers_history": """
        entity_id VARCHAR(30), email VARCHAR(100), firstname VARCHAR(50), lastname VARCHAR(50),
        telephone VARCHAR(20), city VARCHAR(50), country_id VARCHAR(50), group_id VARCHAR(20),
        created_at VARCHAR(20), gender VARCHAR(5), is_subscribed BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.coast_products_history": """
        entity_id VARCHAR(30), name VARCHAR(200), color_attribute VARCHAR(30), category_name VARCHAR(30),
        subcategory_name VARCHAR(50), price NUMERIC(10,2), cost NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        manufacturer VARCHAR(50), season VARCHAR(10), meta_keyword VARCHAR(20), weight NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.coast_orders_history": """
        increment_id VARCHAR(30), customer_id VARCHAR(30), created_at VARCHAR(30),
        grand_total NUMERIC(10,2), status VARCHAR(30), payment_method VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), coupon_code VARCHAR(20), shipping_method VARCHAR(20), store_id VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_magento.coast_order_items_history": """
        order_item_id VARCHAR(30), increment_id VARCHAR(30), entity_id VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    # ─── oracle_commerce ──────────────────────────────────────────
    "rdl_oracle_commerce.debenhams_customers_history": """
        profile_id VARCHAR(30), email_address VARCHAR(100), first_name VARCHAR(50), last_name VARCHAR(50),
        phone_number VARCHAR(20), city VARCHAR(50), country VARCHAR(50), customer_segment VARCHAR(20),
        registration_date VARCHAR(20), gender VARCHAR(5), receive_email BOOLEAN, orders_count INT,
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_oracle_commerce.debenhams_products_history": """
        item_id VARCHAR(30), display_name VARCHAR(200), colour_code VARCHAR(30), category_code VARCHAR(30),
        sub_category_code VARCHAR(50), list_price NUMERIC(10,2), unit_cost NUMERIC(10,2),
        rrp NUMERIC(10,2), brand VARCHAR(50), available_sizes SUPER, is_active BOOLEAN,
        stock_status VARCHAR(20), created_at VARCHAR(30), updated_at VARCHAR(30),
        fabric_type VARCHAR(50), season_year VARCHAR(10), vendor_id VARCHAR(20), shipping_weight NUMERIC(6,2),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_oracle_commerce.debenhams_orders_history": """
        order_number VARCHAR(30), profile_id VARCHAR(30), submitted_date VARCHAR(30),
        price_total NUMERIC(10,2), state VARCHAR(30), payment_type VARCHAR(30),
        discount_amount NUMERIC(10,2), shipping_cost NUMERIC(6,2), item_count INT,
        brand VARCHAR(50), promotion_code VARCHAR(20), shipping_method VARCHAR(20), site_code VARCHAR(10),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
    "rdl_oracle_commerce.debenhams_order_items_history": """
        order_item_id VARCHAR(30), order_number VARCHAR(30), item_id VARCHAR(30),
        quantity INT, unit_price NUMERIC(10,2), size VARCHAR(10),
        discount_pct INT, line_total NUMERIC(10,2), brand VARCHAR(50),
        ingest_date VARCHAR(10), ingest_time VARCHAR(40)
    """,
}


def run_sql(sql, desc=""):
    resp = client.execute_statement(WorkgroupName=WORKGROUP, Database=DB, Sql=sql)
    stmt_id = resp["Id"]
    print(f"  [{desc}] submitted: {stmt_id}")
    while True:
        time.sleep(2)
        status = client.describe_statement(Id=stmt_id)
        s = status["Status"]
        if s in ("FINISHED",):
            print(f"  [{desc}] OK {s}")
            return
        elif s in ("FAILED", "ABORTED"):
            print(f"  [{desc}] FAIL {s}: {status.get('Error', 'unknown')}")
            return
        # else STARTED/SUBMITTED/PICKED — keep waiting


if __name__ == "__main__":
    for table_name, cols in TABLES.items():
        ddl = f"CREATE TABLE IF NOT EXISTS {table_name} ({cols.strip()});"
        run_sql(ddl, table_name)
    print("\nAll raw tables created.")
