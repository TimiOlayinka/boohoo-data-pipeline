------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.tiktok_ads
-- Deduplicated TikTok Ads insights from tiktok_ads_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        advertiser_id,
        ad_id,
        campaign_name,
        objective,
        stat_time_day,
        spend,
        impressions,
        clicks,
        reach,
        frequency,
        ctr,
        cpc,
        cpm,
        conversion_rate,
        conversion,
        cost_per_conversion,
        purchase,
        video_play_actions,
        video_watched_2s,
        video_watched_6s,
        video_views_p25,
        video_views_p50,
        video_views_p75,
        video_views_p100,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'tiktok_ads_history') }}
),
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, stat_time_day, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
    FROM history
)
SELECT
    advertiser_id,
    ad_id,
    campaign_name,
    objective,
    stat_time_day::DATE AS date_nk,
    spend,
    impressions,
    clicks,
    reach,
    frequency,
    ctr,
    cpc,
    cpm,
    conversion_rate,
    conversion,
    cost_per_conversion,
    purchase,
    video_play_actions,
    video_watched_2s,
    video_watched_6s,
    video_views_p25,
    video_views_p50,
    video_views_p75,
    video_views_p100,
    brand,
    ingest_date,
    ingest_ts
FROM dedup WHERE rnk = 1
