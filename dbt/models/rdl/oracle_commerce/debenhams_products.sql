------------------------------------------------------------------------------------------------------------------------
-- rdl_oracle_commerce.debenhams_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT item_id AS product_id, display_name AS product_name, colour_code AS colour, category_code AS category,
           sub_category_code AS subcategory, list_price AS current_price, unit_cost AS cost_price,
           rrp, fabric_type AS material, season_year AS season, is_active, stock_status,
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_oracle_commerce', 'debenhams_products_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY item_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT product_id, product_name, colour, category, subcategory,
       current_price, cost_price, rrp, material, season,
       is_active::BOOLEAN AS is_active, stock_status,
       created_at, updated_at,
       'Debenhams' AS brand, 'oracle_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
