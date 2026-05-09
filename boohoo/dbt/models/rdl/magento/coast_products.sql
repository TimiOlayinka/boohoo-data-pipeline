------------------------------------------------------------------------------------------------------------------------
-- rdl_magento.coast_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT entity_id AS product_id, name AS product_name, color_attribute AS colour, category_name AS category,
           subcategory_name AS subcategory, price AS current_price, cost AS cost_price,
           rrp, manufacturer AS material, season, is_active, stock_status,
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_magento', 'coast_products_history') }}
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
       'Coast' AS brand, 'magento' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
