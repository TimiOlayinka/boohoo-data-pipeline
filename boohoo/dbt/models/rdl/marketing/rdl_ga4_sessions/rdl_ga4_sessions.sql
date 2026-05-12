------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.ga4_sessions
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
session_id,
        user_pseudo_id,
        session_date,
        session_timestamp,
        source,
        medium,
        channel_group,
        utm_campaign,
        device_category,
        country,
        landing_page,
        page_views,
        session_duration_seconds,
        is_bounced,
        is_engaged_session,
        is_new_user,
        transactions,
        revenue,
        add_to_carts,
        checkouts,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'ga4_sessions_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY session_id, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY session_id, brand
        ) AS version_count,
        MD5(
            COALESCE(session_id::VARCHAR, '') || '|' ||
            COALESCE(user_pseudo_id::VARCHAR, '') || '|' ||
            COALESCE(session_date::VARCHAR, '') || '|' ||
            COALESCE(session_timestamp::VARCHAR, '') || '|' ||
            COALESCE(source::VARCHAR, '') || '|' ||
            COALESCE(medium::VARCHAR, '') || '|' ||
            COALESCE(channel_group::VARCHAR, '') || '|' ||
            COALESCE(utm_campaign::VARCHAR, '') || '|' ||
            COALESCE(device_category::VARCHAR, '') || '|' ||
            COALESCE(country::VARCHAR, '') || '|' ||
            COALESCE(landing_page::VARCHAR, '') || '|' ||
            COALESCE(page_views::VARCHAR, '') || '|' ||
            COALESCE(session_duration_seconds::VARCHAR, '') || '|' ||
            COALESCE(is_bounced::VARCHAR, '') || '|' ||
            COALESCE(is_engaged_session::VARCHAR, '') || '|' ||
            COALESCE(is_new_user::VARCHAR, '') || '|' ||
            COALESCE(transactions::VARCHAR, '') || '|' ||
            COALESCE(revenue::VARCHAR, '') || '|' ||
            COALESCE(add_to_carts::VARCHAR, '') || '|' ||
            COALESCE(checkouts::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
    FROM history
)
SELECT
    session_id,
    user_pseudo_id,
    session_date::DATE AS date_nk,
    session_timestamp::TIMESTAMP AS session_timestamp,
    source,
    medium,
    channel_group,
    utm_campaign,
    device_category,
    country,
    landing_page,
    page_views,
    session_duration_seconds,
    is_bounced::BOOLEAN AS is_bounced,
    is_engaged_session::BOOLEAN AS is_engaged_session,
    is_new_user::BOOLEAN AS is_new_user,
    transactions,
    revenue::NUMERIC(18,2) AS revenue,
    add_to_carts,
    checkouts,
    brand,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
