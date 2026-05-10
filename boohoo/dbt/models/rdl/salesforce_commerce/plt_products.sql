------------------------------------------------------------------------------------------------------------------------
-- rdl_salesforce_commerce.plt_products
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        product_id,
        display_name AS product_name,
        c_color AS colour,
        primary_category_id AS category,
        classification_category AS subcategory,
        price_book_price AS current_price,
        c_cost AS cost_price,
        rrp,
        c_fabric_composition AS material,
        c_season AS season,
        is_active,
        stock_status,
        created_at,
        updated_at,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_salesforce_commerce', 'plt_products_history') }}
),
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
    FROM history
)
SELECT
    product_id,
    product_name,
    colour,
    category,
    subcategory,
    current_price,
    cost_price,
    rrp,
    material,
    season,
    is_active::BOOLEAN AS is_active,
    stock_status,
    created_at,
    updated_at,
    'PrettyLittleThing' AS brand,
    'salesforce_commerce' AS source_system,
    ingest_date,
    ingest_ts
FROM dedup WHERE rnk = 1
