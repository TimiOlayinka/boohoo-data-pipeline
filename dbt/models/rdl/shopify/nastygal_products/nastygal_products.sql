------------------------------------------------------------------------------------------------------------------------
-- rdl_shopify.nastygal_products
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
variant_id AS product_id,
        title AS product_name,
        option1 AS colour,
        product_type AS category,
        tags AS subcategory,
        price AS current_price,
        cost AS cost_price,
        rrp,
        vendor AS material,
        created_at AS season,
        is_active,
        stock_status,
        created_at,
        updated_at,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_shopify', 'nastygal_products_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY product_id
        ) AS version_count,
        MD5(
            COALESCE(product_id::VARCHAR, '') || '|' ||
            COALESCE(product_name::VARCHAR, '') || '|' ||
            COALESCE(colour::VARCHAR, '') || '|' ||
            COALESCE(category::VARCHAR, '') || '|' ||
            COALESCE(subcategory::VARCHAR, '') || '|' ||
            COALESCE(current_price::VARCHAR, '') || '|' ||
            COALESCE(cost_price::VARCHAR, '') || '|' ||
            COALESCE(rrp::VARCHAR, '') || '|' ||
            COALESCE(material::VARCHAR, '') || '|' ||
            COALESCE(season::VARCHAR, '') || '|' ||
            COALESCE(is_active::VARCHAR, '') || '|' ||
            COALESCE(stock_status::VARCHAR, '') || '|' ||
            COALESCE(created_at::VARCHAR, '') || '|' ||
            COALESCE(updated_at::VARCHAR, '')
        ) AS record_hash
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
    ingest_date,
    ingest_ts,
    'NastyGal' AS brand,
    'shopify' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
