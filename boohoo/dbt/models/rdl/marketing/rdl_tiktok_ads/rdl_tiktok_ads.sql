------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.tiktok_ads
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
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
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, stat_time_day, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY ad_id, stat_time_day, brand
        ) AS version_count,
        MD5(
            COALESCE(advertiser_id::VARCHAR, '') || '|' ||
            COALESCE(ad_id::VARCHAR, '') || '|' ||
            COALESCE(campaign_name::VARCHAR, '') || '|' ||
            COALESCE(objective::VARCHAR, '') || '|' ||
            COALESCE(stat_time_day::VARCHAR, '') || '|' ||
            COALESCE(spend::VARCHAR, '') || '|' ||
            COALESCE(impressions::VARCHAR, '') || '|' ||
            COALESCE(clicks::VARCHAR, '') || '|' ||
            COALESCE(reach::VARCHAR, '') || '|' ||
            COALESCE(frequency::VARCHAR, '') || '|' ||
            COALESCE(ctr::VARCHAR, '') || '|' ||
            COALESCE(cpc::VARCHAR, '') || '|' ||
            COALESCE(cpm::VARCHAR, '') || '|' ||
            COALESCE(conversion_rate::VARCHAR, '') || '|' ||
            COALESCE(conversion::VARCHAR, '') || '|' ||
            COALESCE(cost_per_conversion::VARCHAR, '') || '|' ||
            COALESCE(purchase::VARCHAR, '') || '|' ||
            COALESCE(video_play_actions::VARCHAR, '') || '|' ||
            COALESCE(video_watched_2s::VARCHAR, '') || '|' ||
            COALESCE(video_watched_6s::VARCHAR, '') || '|' ||
            COALESCE(video_views_p25::VARCHAR, '') || '|' ||
            COALESCE(video_views_p50::VARCHAR, '') || '|' ||
            COALESCE(video_views_p75::VARCHAR, '') || '|' ||
            COALESCE(video_views_p100::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
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
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
