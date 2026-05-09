"""Generate all dbt models following HnB naming convention:
  rdl_{source} → history dedup + field normalization
  odl          → star schema (dim_*, fact_*)
  adl/bi       → materialized views for dashboards
"""
import os

BASE = r"d:\BellosData\aws-data-portfolio\dbt\models"

# ============================================================
# RDL MODELS — one per brand per dataset, dedup from _history
# ============================================================
RDL_CUSTOMERS = {
    ("boohoo_commerce", "boohoo"): {
        "fields": "customer_id, email, first_name, last_name, phone, city, country,\n           segment AS customer_segment, signup_date, gender, is_subscribed",
        "pk": "customer_id", "brand": "Boohoo",
    },
    ("boohoo_commerce", "boohoo_man"): {
        "fields": "customer_id, email, first_name, last_name, phone, city, country,\n           segment AS customer_segment, signup_date, gender, is_subscribed",
        "pk": "customer_id", "brand": "Boohoo Man",
    },
    ("salesforce_commerce", "plt"): {
        "fields": "customer_no AS customer_id, email, first_name, last_name, phone_home AS phone, city,\n           country_code AS country, customer_group AS customer_segment, creation_date AS signup_date, gender, email_opt_in AS is_subscribed",
        "pk": "customer_no", "brand": "PrettyLittleThing",
    },
    ("shopify", "nastygal"): {
        "fields": "id AS customer_id, email, first_name, last_name, phone, city,\n           country, tags AS customer_segment, created_at AS signup_date, NULL AS gender, accepts_marketing AS is_subscribed",
        "pk": "id", "brand": "NastyGal",
    },
    ("magento", "karen_millen"): {
        "fields": "entity_id AS customer_id, email, firstname AS first_name, lastname AS last_name, telephone AS phone, city,\n           country_id AS country, group_id AS customer_segment, created_at AS signup_date, gender, is_subscribed",
        "pk": "entity_id", "brand": "Karen Millen",
    },
    ("magento", "coast"): {
        "fields": "entity_id AS customer_id, email, firstname AS first_name, lastname AS last_name, telephone AS phone, city,\n           country_id AS country, group_id AS customer_segment, created_at AS signup_date, gender, is_subscribed",
        "pk": "entity_id", "brand": "Coast",
    },
    ("oracle_commerce", "debenhams"): {
        "fields": "profile_id AS customer_id, email_address AS email, first_name, last_name, phone_number AS phone, city,\n           country, customer_segment, registration_date AS signup_date, gender, receive_email AS is_subscribed",
        "pk": "profile_id", "brand": "Debenhams",
    },
}

RDL_PRODUCTS = {
    ("boohoo_commerce", "boohoo"): {
        "fields": "sku AS product_id, product_name, colour, department AS category,\n           product_type AS subcategory, selling_price AS current_price, cost_price,\n           rrp, material, season_code AS season, is_active, stock_status",
        "pk": "sku", "brand": "Boohoo",
    },
    ("boohoo_commerce", "boohoo_man"): {
        "fields": "sku AS product_id, product_name, colour, department AS category,\n           product_type AS subcategory, selling_price AS current_price, cost_price,\n           rrp, material, season_code AS season, is_active, stock_status",
        "pk": "sku", "brand": "Boohoo Man",
    },
    ("salesforce_commerce", "plt"): {
        "fields": "product_id, display_name AS product_name, c_color AS colour, primary_category_id AS category,\n           classification_category AS subcategory, price_book_price AS current_price, c_cost AS cost_price,\n           rrp, c_fabric_composition AS material, c_season AS season, is_active, stock_status",
        "pk": "product_id", "brand": "PrettyLittleThing",
    },
    ("shopify", "nastygal"): {
        "fields": "variant_id AS product_id, title AS product_name, option1 AS colour, product_type AS category,\n           tags AS subcategory, price AS current_price, cost AS cost_price,\n           rrp, vendor AS material, created_at AS season, is_active, stock_status",
        "pk": "variant_id", "brand": "NastyGal",
    },
    ("magento", "karen_millen"): {
        "fields": "entity_id AS product_id, name AS product_name, color_attribute AS colour, category_name AS category,\n           subcategory_name AS subcategory, price AS current_price, cost AS cost_price,\n           rrp, manufacturer AS material, season, is_active, stock_status",
        "pk": "entity_id", "brand": "Karen Millen",
    },
    ("magento", "coast"): {
        "fields": "entity_id AS product_id, name AS product_name, color_attribute AS colour, category_name AS category,\n           subcategory_name AS subcategory, price AS current_price, cost AS cost_price,\n           rrp, manufacturer AS material, season, is_active, stock_status",
        "pk": "entity_id", "brand": "Coast",
    },
    ("oracle_commerce", "debenhams"): {
        "fields": "item_id AS product_id, display_name AS product_name, colour_code AS colour, category_code AS category,\n           sub_category_code AS subcategory, list_price AS current_price, unit_cost AS cost_price,\n           rrp, fabric_type AS material, season_year AS season, is_active, stock_status",
        "pk": "item_id", "brand": "Debenhams",
    },
}

RDL_ORDERS = {
    ("boohoo_commerce", "boohoo"): {
        "fields": "order_id, customer_id, order_date AS order_timestamp,\n           order_total AS total_amount, order_status AS status, payment_method,\n           discount_amount, shipping_cost, item_count, promo_code, delivery_method, warehouse_id AS fulfilment_centre",
        "pk": "order_id", "brand": "Boohoo",
    },
    ("boohoo_commerce", "boohoo_man"): {
        "fields": "order_id, customer_id, order_date AS order_timestamp,\n           order_total AS total_amount, order_status AS status, payment_method,\n           discount_amount, shipping_cost, item_count, promo_code, delivery_method, warehouse_id AS fulfilment_centre",
        "pk": "order_id", "brand": "Boohoo Man",
    },
    ("salesforce_commerce", "plt"): {
        "fields": "order_no AS order_id, customer_no AS customer_id, creation_date AS order_timestamp,\n           order_total AS total_amount, status, payment_instrument AS payment_method,\n           discount_amount, shipping_cost, item_count, coupon_code AS promo_code, shipment_method_id AS delivery_method, site_id AS fulfilment_centre",
        "pk": "order_no", "brand": "PrettyLittleThing",
    },
    ("shopify", "nastygal"): {
        "fields": "id AS order_id, customer_id, created_at AS order_timestamp,\n           total_price AS total_amount, financial_status AS status, gateway AS payment_method,\n           discount_amount, shipping_cost, item_count, discount_codes AS promo_code, fulfillment_status AS delivery_method, source_name AS fulfilment_centre",
        "pk": "id", "brand": "NastyGal",
    },
    ("magento", "karen_millen"): {
        "fields": "increment_id AS order_id, customer_id, created_at AS order_timestamp,\n           grand_total AS total_amount, status, payment_method,\n           discount_amount, shipping_cost, item_count, coupon_code AS promo_code, shipping_method AS delivery_method, store_id AS fulfilment_centre",
        "pk": "increment_id", "brand": "Karen Millen",
    },
    ("magento", "coast"): {
        "fields": "increment_id AS order_id, customer_id, created_at AS order_timestamp,\n           grand_total AS total_amount, status, payment_method,\n           discount_amount, shipping_cost, item_count, coupon_code AS promo_code, shipping_method AS delivery_method, store_id AS fulfilment_centre",
        "pk": "increment_id", "brand": "Coast",
    },
    ("oracle_commerce", "debenhams"): {
        "fields": "order_number AS order_id, profile_id AS customer_id, submitted_date AS order_timestamp,\n           price_total AS total_amount, state AS status, payment_type AS payment_method,\n           discount_amount, shipping_cost, item_count, promotion_code AS promo_code, shipping_method AS delivery_method, site_code AS fulfilment_centre",
        "pk": "order_number", "brand": "Debenhams",
    },
}


def rdl_customer_sql(source, brand_key, cfg):
    return f"""------------------------------------------------------------------------------------------------------------------------
-- rdl_{source}.{brand_key}_customers
-- Deduplicated from {brand_key}_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT {cfg['fields']},
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{{{ source('rdl_{source}', '{brand_key}_customers_history') }}}}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY customer_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT customer_id, email, first_name, last_name, phone, city, country,
       customer_segment, signup_date::DATE AS registration_date, gender,
       is_subscribed::BOOLEAN AS is_marketing_opted_in,
       '{cfg['brand']}' AS brand, '{source}' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
"""


def rdl_product_sql(source, brand_key, cfg):
    return f"""------------------------------------------------------------------------------------------------------------------------
-- rdl_{source}.{brand_key}_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT {cfg['fields']},
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{{{ source('rdl_{source}', '{brand_key}_products_history') }}}}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY product_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT product_id, product_name, colour, category, subcategory,
       current_price, cost_price, rrp, material, season,
       is_active::BOOLEAN AS is_active, stock_status,
       created_at, updated_at,
       '{cfg['brand']}' AS brand, '{source}' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
"""


def rdl_order_sql(source, brand_key, cfg):
    return f"""------------------------------------------------------------------------------------------------------------------------
-- rdl_{source}.{brand_key}_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT {cfg['fields']},
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{{{ source('rdl_{source}', '{brand_key}_orders_history') }}}}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY order_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT order_id, customer_id, order_timestamp::TIMESTAMP AS order_timestamp,
       total_amount, status, payment_method,
       discount_amount, shipping_cost, item_count,
       promo_code, delivery_method, fulfilment_centre,
       '{cfg['brand']}' AS brand, '{source}' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
"""


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    print(f"  {os.path.relpath(path, BASE)}")


# Write RDL models
print("RDL models:")
for (src, brand_key), cfg in RDL_CUSTOMERS.items():
    write(os.path.join(BASE, "rdl", src, f"{brand_key}_customers.sql"), rdl_customer_sql(src, brand_key, cfg))
for (src, brand_key), cfg in RDL_PRODUCTS.items():
    write(os.path.join(BASE, "rdl", src, f"{brand_key}_products.sql"), rdl_product_sql(src, brand_key, cfg))
for (src, brand_key), cfg in RDL_ORDERS.items():
    write(os.path.join(BASE, "rdl", src, f"{brand_key}_orders.sql"), rdl_order_sql(src, brand_key, cfg))

# ============================================================
# ODL MODELS — star schema (dim_*, fact_*)
# ============================================================
BRANDS = ["boohoo","boohoo_man","plt","nastygal","karen_millen","coast","debenhams"]
SOURCES = ["boohoo_commerce","boohoo_commerce","salesforce_commerce","shopify","magento","magento","oracle_commerce"]

print("\nODL models:")

# dim_customers
refs = "\nUNION ALL\n".join([f"SELECT * FROM {{{{ ref('{b}_customers') }}}}" for b in BRANDS])
dim_customers = f"""------------------------------------------------------------------------------------------------------------------------
-- odl.dim_customers
-- Unified customer dimension across all Boohoo Group brands (star schema)
------------------------------------------------------------------------------------------------------------------------
WITH all_customers AS (
{refs}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY email ORDER BY registration_date DESC, ingest_date DESC
    ) AS rnk
    FROM all_customers
)
SELECT
    MD5(customer_id || '|' || brand) AS customer_sk,
    customer_id                      AS customer_nk,
    email,
    first_name,
    last_name,
    phone,
    city,
    country,
    customer_segment,
    registration_date,
    gender,
    is_marketing_opted_in,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM dedup WHERE rnk = 1
"""
write(os.path.join(BASE, "odl", "dim", "dim_customers.sql"), dim_customers)

# dim_products
refs = "\nUNION ALL\n".join([f"SELECT * FROM {{{{ ref('{b}_products') }}}}" for b in BRANDS])
dim_products = f"""------------------------------------------------------------------------------------------------------------------------
-- odl.dim_products
-- Unified product dimension with calculated margin metrics
------------------------------------------------------------------------------------------------------------------------
WITH all_products AS (
{refs}
)
SELECT
    MD5(product_id || '|' || brand) AS product_sk,
    product_id                      AS product_nk,
    product_name,
    colour,
    category,
    subcategory,
    current_price,
    cost_price,
    rrp,
    CASE WHEN rrp > 0 THEN ROUND((1 - current_price / rrp) * 100, 1) ELSE 0 END AS discount_pct,
    ROUND(current_price - cost_price, 2) AS margin,
    CASE WHEN current_price > 0 THEN ROUND((current_price - cost_price) / current_price * 100, 1) ELSE 0 END AS margin_pct,
    material,
    season,
    is_active,
    stock_status,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM all_products
"""
write(os.path.join(BASE, "odl", "dim", "dim_products.sql"), dim_products)

# dim_time (conformed dimension)
dim_time = """------------------------------------------------------------------------------------------------------------------------
-- odl.dim_time
-- Conformed date dimension
------------------------------------------------------------------------------------------------------------------------
WITH date_spine AS (
    SELECT (DATE '2024-01-01' + n)::DATE AS date_day
    FROM (SELECT ROW_NUMBER() OVER () - 1 AS n FROM pg_catalog.pg_class LIMIT 1096) seq
)
SELECT
    date_day                                    AS date_day,
    EXTRACT(DOW FROM date_day)                 AS day_of_week,
    TO_CHAR(date_day, 'Day')                   AS day_name,
    EXTRACT(DAY FROM date_day)                 AS day_of_month,
    EXTRACT(MONTH FROM date_day)               AS month_number,
    TO_CHAR(date_day, 'Month')                 AS month_name,
    EXTRACT(QUARTER FROM date_day)             AS quarter,
    EXTRACT(YEAR FROM date_day)                AS year,
    TO_CHAR(date_day, 'IYYY-IW')              AS iso_week,
    CASE WHEN EXTRACT(DOW FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
    CASE WHEN EXTRACT(MONTH FROM date_day) IN (11,12,1) THEN TRUE ELSE FALSE END AS is_peak_season
FROM date_spine
"""
write(os.path.join(BASE, "odl", "dim", "dim_time.sql"), dim_time)

# fact_orders
refs = "\nUNION ALL\n".join([f"SELECT * FROM {{{{ ref('{b}_orders') }}}}" for b in BRANDS])
fact_orders = f"""------------------------------------------------------------------------------------------------------------------------
-- odl.fact_orders
-- Unified order fact table with surrogate keys to dimensions
------------------------------------------------------------------------------------------------------------------------
WITH all_orders AS (
{refs}
)
SELECT
    MD5(order_id || '|' || brand)       AS order_sk,
    order_id                            AS order_nk,
    MD5(customer_id || '|' || brand)    AS customer_sk,
    order_timestamp,
    order_timestamp::DATE               AS order_date,
    EXTRACT(YEAR FROM order_timestamp)  AS order_year,
    EXTRACT(MONTH FROM order_timestamp) AS order_month,
    EXTRACT(DOW FROM order_timestamp)   AS order_day_of_week,
    total_amount,
    discount_amount,
    shipping_cost,
    total_amount + shipping_cost                AS gross_revenue,
    total_amount - COALESCE(discount_amount, 0) AS net_revenue,
    status,
    payment_method,
    promo_code,
    delivery_method,
    fulfilment_centre,
    item_count,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM all_orders
"""
write(os.path.join(BASE, "odl", "fact", "fact_orders.sql"), fact_orders)

# map_brand (mapping table)
map_brand = """------------------------------------------------------------------------------------------------------------------------
-- odl.map_brand
-- Brand reference mapping
------------------------------------------------------------------------------------------------------------------------
SELECT 'Boohoo'             AS brand, 'boohoo_commerce'       AS source_system, 'Value'   AS brand_tier, 'boohoo.com'              AS website
UNION ALL SELECT 'Boohoo Man',         'boohoo_commerce',       'Value',   'boohooman.com'
UNION ALL SELECT 'PrettyLittleThing',  'salesforce_commerce',   'Value',   'prettylittlething.com'
UNION ALL SELECT 'NastyGal',           'shopify',               'Mid',     'nastygal.com'
UNION ALL SELECT 'Karen Millen',       'magento',               'Premium', 'karenmillen.com'
UNION ALL SELECT 'Coast',              'magento',               'Premium', 'coast-stores.com'
UNION ALL SELECT 'Debenhams',          'oracle_commerce',       'Mid',     'debenhams.com'
"""
write(os.path.join(BASE, "odl", "map", "map_brand.sql"), map_brand)

# ============================================================
# ADL/BI MODELS — materialized views for dashboards
# ============================================================
print("\nADL/BI models:")

fact_revenue_by_brand = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_revenue_by_brand
-- Pre-aggregated revenue metrics by brand - feeds Looker Studio
------------------------------------------------------------------------------------------------------------------------
SELECT
    o.ingest_date,
    o.brand,
    b.brand_tier,
    COUNT(DISTINCT o.order_nk)          AS total_orders,
    COUNT(DISTINCT o.customer_sk)       AS unique_customers,
    SUM(o.total_amount)                 AS gross_revenue,
    SUM(o.net_revenue)                  AS net_revenue,
    SUM(o.discount_amount)              AS total_discounts,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    ROUND(SUM(o.discount_amount) / NULLIF(SUM(o.gross_revenue), 0) * 100, 1) AS discount_rate_pct,
    SUM(o.item_count)                   AS total_items_sold
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('map_brand') }} b ON o.brand = b.brand
GROUP BY 1, 2, 3
"""
write(os.path.join(BASE, "adl", "bi", "fact_revenue_by_brand.sql"), fact_revenue_by_brand)

fact_daily_sales = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_daily_sales
-- Daily sales time series for trend analysis
------------------------------------------------------------------------------------------------------------------------
SELECT
    o.order_date,
    o.brand,
    b.brand_tier,
    o.order_year,
    o.order_month,
    o.order_day_of_week,
    COUNT(*)                            AS order_count,
    SUM(o.total_amount)                 AS daily_revenue,
    SUM(o.net_revenue)                  AS daily_net_revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    SUM(o.item_count)                   AS items_sold,
    COUNT(DISTINCT o.customer_sk)       AS unique_customers
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('map_brand') }} b ON o.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 6
"""
write(os.path.join(BASE, "adl", "bi", "fact_daily_sales.sql"), fact_daily_sales)

fact_customer_segments = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_customer_segments
-- Customer segmentation analysis for CRM dashboards
------------------------------------------------------------------------------------------------------------------------
SELECT
    c.brand,
    b.brand_tier,
    c.customer_segment,
    c.gender,
    c.country,
    COUNT(*)                                                AS customer_count,
    COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)    AS opted_in_count,
    ROUND(COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1) AS opt_in_rate_pct,
    MIN(c.registration_date)                                AS earliest_registration,
    MAX(c.registration_date)                                AS latest_registration,
    c.ingest_date
FROM {{ ref('dim_customers') }} c
LEFT JOIN {{ ref('map_brand') }} b ON c.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 11
"""
write(os.path.join(BASE, "adl", "bi", "fact_customer_segments.sql"), fact_customer_segments)

fact_product_performance = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_product_performance
-- Product performance metrics for merchandising dashboards
------------------------------------------------------------------------------------------------------------------------
SELECT
    p.brand,
    b.brand_tier,
    p.category,
    p.subcategory,
    p.stock_status,
    COUNT(DISTINCT p.product_nk)                AS sku_count,
    ROUND(AVG(p.current_price), 2)              AS avg_selling_price,
    ROUND(AVG(p.rrp), 2)                        AS avg_rrp,
    ROUND(AVG(p.margin_pct), 1)                 AS avg_margin_pct,
    ROUND(AVG(p.discount_pct), 1)               AS avg_discount_pct,
    COUNT(CASE WHEN p.is_active THEN 1 END)     AS active_skus,
    COUNT(CASE WHEN NOT p.is_active THEN 1 END) AS inactive_skus,
    p.ingest_date
FROM {{ ref('dim_products') }} p
LEFT JOIN {{ ref('map_brand') }} b ON p.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 13
"""
write(os.path.join(BASE, "adl", "bi", "fact_product_performance.sql"), fact_product_performance)

print("\nAll models generated.")
