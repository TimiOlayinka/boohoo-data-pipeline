------------------------------------------------------------------------------------------------------------------------
-- odl.dim_products
-- Unified product dimension with calculated margin metrics
------------------------------------------------------------------------------------------------------------------------
WITH all_products AS (
SELECT * FROM {{ ref('boohoo_products') }}
UNION ALL
SELECT * FROM {{ ref('boohoo_man_products') }}
UNION ALL
SELECT * FROM {{ ref('plt_products') }}
UNION ALL
SELECT * FROM {{ ref('nastygal_products') }}
UNION ALL
SELECT * FROM {{ ref('karen_millen_products') }}
UNION ALL
SELECT * FROM {{ ref('coast_products') }}
UNION ALL
SELECT * FROM {{ ref('debenhams_products') }}
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
