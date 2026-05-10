------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.email_campaigns
-- Deduplicated email campaign performance from email_campaigns_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
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
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, send_date, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
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
    ingest_ts
FROM dedup WHERE rnk = 1
