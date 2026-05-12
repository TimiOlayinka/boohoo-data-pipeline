------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.email_campaigns
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
campaign_id,
        campaign_name,
        campaign_type,
        subject_line,
        send_date,
        send_timestamp,
        list_size,
        delivered,
        opened,
        unique_opens,
        clicked,
        unique_clicks,
        unsubscribed,
        bounced,
        spam_complaints,
        converted,
        revenue,
        open_rate,
        click_rate,
        click_to_open_rate,
        conversion_rate,
        revenue_per_email,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'email_campaigns_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, send_date, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY campaign_id, send_date, brand
        ) AS version_count,
        MD5(
            COALESCE(campaign_id::VARCHAR, '') || '|' ||
            COALESCE(campaign_name::VARCHAR, '') || '|' ||
            COALESCE(campaign_type::VARCHAR, '') || '|' ||
            COALESCE(subject_line::VARCHAR, '') || '|' ||
            COALESCE(send_date::VARCHAR, '') || '|' ||
            COALESCE(send_timestamp::VARCHAR, '') || '|' ||
            COALESCE(list_size::VARCHAR, '') || '|' ||
            COALESCE(delivered::VARCHAR, '') || '|' ||
            COALESCE(opened::VARCHAR, '') || '|' ||
            COALESCE(unique_opens::VARCHAR, '') || '|' ||
            COALESCE(clicked::VARCHAR, '') || '|' ||
            COALESCE(unique_clicks::VARCHAR, '') || '|' ||
            COALESCE(unsubscribed::VARCHAR, '') || '|' ||
            COALESCE(bounced::VARCHAR, '') || '|' ||
            COALESCE(spam_complaints::VARCHAR, '') || '|' ||
            COALESCE(converted::VARCHAR, '') || '|' ||
            COALESCE(revenue::VARCHAR, '') || '|' ||
            COALESCE(open_rate::VARCHAR, '') || '|' ||
            COALESCE(click_rate::VARCHAR, '') || '|' ||
            COALESCE(click_to_open_rate::VARCHAR, '') || '|' ||
            COALESCE(conversion_rate::VARCHAR, '') || '|' ||
            COALESCE(revenue_per_email::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
    FROM history
)
SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    subject_line,
    send_date::DATE AS date_nk,
    send_timestamp::TIMESTAMP AS send_timestamp,
    list_size,
    delivered,
    opened,
    unique_opens,
    clicked,
    unique_clicks,
    unsubscribed,
    bounced,
    spam_complaints,
    converted,
    revenue::NUMERIC(18,2) AS revenue,
    open_rate::NUMERIC(8,2) AS open_rate,
    click_rate::NUMERIC(8,2) AS click_rate,
    click_to_open_rate::NUMERIC(8,2) AS click_to_open_rate,
    conversion_rate::NUMERIC(8,2) AS conversion_rate,
    revenue_per_email::NUMERIC(10,4) AS revenue_per_email,
    brand,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
