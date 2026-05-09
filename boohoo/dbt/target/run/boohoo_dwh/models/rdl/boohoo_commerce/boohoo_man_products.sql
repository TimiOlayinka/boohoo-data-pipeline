

  create view "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_man_products__dbt_tmp" as (
    ------------------------------------------------------------------------------------------------------------------------
-- rdl_boohoo_commerce.boohoo_man_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT sku AS product_id, product_name, colour, department AS category,
           product_type AS subcategory, selling_price AS current_price, cost_price,
           rrp, material, season_code AS season, is_active, stock_status,
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_man_products_history"
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
       'Boohoo Man' AS brand, 'boohoo_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
  ) ;
