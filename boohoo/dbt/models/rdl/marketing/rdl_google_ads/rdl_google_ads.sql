------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.google_ads
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
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
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date_day, device, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY ad_id, date_day, device, brand
        ) AS version_count,
        MD5(
            COALESCE(customer_id::VARCHAR, '') || '|' ||
            COALESCE(customer_name::VARCHAR, '') || '|' ||
            COALESCE(campaign_id::VARCHAR, '') || '|' ||
            COALESCE(campaign_name::VARCHAR, '') || '|' ||
            COALESCE(campaign_status::VARCHAR, '') || '|' ||
            COALESCE(channel_type::VARCHAR, '') || '|' ||
            COALESCE(ad_group_id::VARCHAR, '') || '|' ||
            COALESCE(ad_id::VARCHAR, '') || '|' ||
            COALESCE(date_day::VARCHAR, '') || '|' ||
            COALESCE(device::VARCHAR, '') || '|' ||
            COALESCE(ad_network_type::VARCHAR, '') || '|' ||
            COALESCE(cost_micros::VARCHAR, '') || '|' ||
            COALESCE(spend::VARCHAR, '') || '|' ||
            COALESCE(impressions::VARCHAR, '') || '|' ||
            COALESCE(clicks::VARCHAR, '') || '|' ||
            COALESCE(interactions::VARCHAR, '') || '|' ||
            COALESCE(conversions::VARCHAR, '') || '|' ||
            COALESCE(conversions_value::VARCHAR, '') || '|' ||
            COALESCE(all_conversions::VARCHAR, '') || '|' ||
            COALESCE(all_conversions_value::VARCHAR, '') || '|' ||
            COALESCE(video_quartile_p25_rate::VARCHAR, '') || '|' ||
            COALESCE(video_quartile_p50_rate::VARCHAR, '') || '|' ||
            COALESCE(video_quartile_p75_rate::VARCHAR, '') || '|' ||
            COALESCE(video_quartile_p100_rate::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
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
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
