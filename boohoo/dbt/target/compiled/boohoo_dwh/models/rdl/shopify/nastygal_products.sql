------------------------------------------------------------------------------------------------------------------------
-- rdl_shopify.nastygal_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT variant_id AS product_id, title AS product_name, option1 AS colour, product_type AS category,
           tags AS subcategory, price AS current_price, cost AS cost_price,
           rrp, vendor AS material, created_at AS season, is_active, stock_status,
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "boohoo_dwh"."rdl_shopify"."nastygal_products_history"
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
       'NastyGal' AS brand, 'shopify' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1