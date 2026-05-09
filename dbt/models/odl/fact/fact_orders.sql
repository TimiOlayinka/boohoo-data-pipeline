------------------------------------------------------------------------------------------------------------------------
-- odl.fact_orders
-- Unified order fact table with surrogate keys to dimensions
------------------------------------------------------------------------------------------------------------------------
WITH all_orders AS (
SELECT * FROM {{ ref('boohoo_orders') }}
UNION ALL
SELECT * FROM {{ ref('boohoo_man_orders') }}
UNION ALL
SELECT * FROM {{ ref('plt_orders') }}
UNION ALL
SELECT * FROM {{ ref('nastygal_orders') }}
UNION ALL
SELECT * FROM {{ ref('karen_millen_orders') }}
UNION ALL
SELECT * FROM {{ ref('coast_orders') }}
UNION ALL
SELECT * FROM {{ ref('debenhams_orders') }}
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
