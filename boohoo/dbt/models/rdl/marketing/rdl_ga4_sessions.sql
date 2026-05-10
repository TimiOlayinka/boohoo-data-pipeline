------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.ga4_sessions
-- Deduplicated GA4 web sessions from ga4_sessions_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
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
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY session_id, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
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
    ingest_ts
FROM dedup WHERE rnk = 1
