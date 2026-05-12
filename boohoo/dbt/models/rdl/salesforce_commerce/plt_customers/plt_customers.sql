------------------------------------------------------------------------------------------------------------------------
-- rdl_salesforce_commerce.plt_customers
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
customer_no AS customer_id,
        email,
        first_name,
        last_name,
        phone_home AS phone,
        city,
        country_code AS country,
        customer_group AS customer_segment,
        creation_date AS signup_date,
        gender,
        email_opt_in AS is_subscribed,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_salesforce_commerce', 'plt_customers_history') }}
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
    'PrettyLittleThing' AS brand,
    'salesforce_commerce' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
