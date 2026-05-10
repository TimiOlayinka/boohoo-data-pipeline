------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.google_ads
-- Deduplicated Google Ads performance from google_ads_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        customer_id,
        customer_name,
        campaign_id,
        campaign_name,
        campaign_status,
        channel_type,
        ad_group_id,
        ad_id,
        date_day,
        device,
        ad_network_type,
        cost_micros,
        spend,
        impressions,
        clicks,
        interactions,
        conversions,
        conversions_value,
        all_conversions,
        all_conversions_value,
        video_quartile_p25_rate,
        video_quartile_p50_rate,
        video_quartile_p75_rate,
        video_quartile_p100_rate,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'google_ads_history') }}
),
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date_day, device, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
    FROM history
)
SELECT
    customer_id,
    customer_name,
    campaign_id,
    campaign_name,
    campaign_status,
    channel_type,
    ad_group_id,
    ad_id,
    date_day::DATE AS date_nk,
    device,
    ad_network_type,
    cost_micros,
    spend,
    impressions,
    clicks,
    interactions,
    conversions,
    conversions_value,
    all_conversions,
    all_conversions_value,
    video_quartile_p25_rate,
    video_quartile_p50_rate,
    video_quartile_p75_rate,
    video_quartile_p100_rate,
    brand,
    ingest_date,
    ingest_ts
FROM dedup WHERE rnk = 1
