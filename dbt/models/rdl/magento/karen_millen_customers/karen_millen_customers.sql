------------------------------------------------------------------------------------------------------------------------
-- rdl_magento.karen_millen_customers
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
entity_id AS customer_id,
        email,
        firstname AS first_name,
        lastname AS last_name,
        telephone AS phone,
        city,
        country_id AS country,
        group_id AS customer_segment,
        created_at AS signup_date,
        gender,
        is_subscribed,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_magento', 'karen_millen_customers_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS version_count,
        MD5(
            COALESCE(customer_id::VARCHAR, '') || '|' ||
            COALESCE(email::VARCHAR, '') || '|' ||
            COALESCE(first_name::VARCHAR, '') || '|' ||
            COALESCE(last_name::VARCHAR, '') || '|' ||
            COALESCE(phone::VARCHAR, '') || '|' ||
            COALESCE(city::VARCHAR, '') || '|' ||
            COALESCE(country::VARCHAR, '') || '|' ||
            COALESCE(customer_segment::VARCHAR, '') || '|' ||
            COALESCE(signup_date::VARCHAR, '') || '|' ||
            COALESCE(gender::VARCHAR, '') || '|' ||
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
    signup_date::DATE AS registration_date,
    gender,
    is_subscribed::BOOLEAN AS is_marketing_opted_in,
    ingest_date,
    ingest_ts,
    'Karen Millen' AS brand,
    'magento' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
