------------------------------------------------------------------------------------------------------------------------
-- rdl_boohoo_commerce.boohoo_customers
-- Full-history model: ALL versions of every customer are preserved (no dedup filter)
-- Dedup responsibility moves to ODL — use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5 hash) → SELECT ALL
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        customer_id,
        email,
        first_name,
        last_name,
        phone,
        city,
        country,
        segment AS customer_segment,
        signup_date,
        gender,
        is_subscribed,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_boohoo_commerce', 'boohoo_customers_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS version_count,
        MD5(
            COALESCE(customer_id, '') || '|' ||
            COALESCE(email, '') || '|' ||
            COALESCE(first_name, '') || '|' ||
            COALESCE(last_name, '') || '|' ||
            COALESCE(phone, '') || '|' ||
            COALESCE(city, '') || '|' ||
            COALESCE(country, '') || '|' ||
            COALESCE(customer_segment, '') || '|' ||
            COALESCE(signup_date::VARCHAR, '') || '|' ||
            COALESCE(gender, '') || '|' ||
            COALESCE(is_subscribed::VARCHAR, '')
        ) AS record_hash
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
    signup_date::DATE     AS registration_date,
    gender,
    is_subscribed::BOOLEAN AS is_marketing_opted_in,
    'Boohoo'              AS brand,
    'boohoo_commerce'     AS source_system,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1       AS is_latest,
    version_count,
    record_hash
FROM versioned
