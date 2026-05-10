------------------------------------------------------------------------------------------------------------------------
-- rdl_shopify.nastygal_customers
-- Deduplicated from nastygal_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        id AS customer_id,
        email,
        first_name,
        last_name,
        phone,
        city,
        country,
        tags AS customer_segment,
        created_at AS signup_date,
        NULL AS gender,
        accepts_marketing AS is_subscribed,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_shopify', 'nastygal_customers_history') }}
),
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
    FROM history
)
SELECT
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    city,
    country,
    customer_segment,
    signup_date::DATE AS registration_date,
    gender,
    CASE WHEN is_subscribed IN ('true', 'True', '1', 'yes') THEN TRUE ELSE FALSE END AS is_marketing_opted_in,
    'NastyGal' AS brand,
    'shopify' AS source_system,
    ingest_date,
    ingest_ts
FROM dedup WHERE rnk = 1
