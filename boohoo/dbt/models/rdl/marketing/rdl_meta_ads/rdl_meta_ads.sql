------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.meta_ads
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
campaign_id,
        campaign_name,
        objective,
        account_id,
        publisher_platform,
        date_start,
        spend,
        impressions,
        clicks,
        reach,
        frequency,
        cpc,
        cpm,
        ctr,
        outbound_clicks,
        outbound_clicks_ctr,
        video_p25_watched,
        video_p50_watched,
        video_p75_watched,
        video_p100_watched,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'meta_ads_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, date_start, publisher_platform, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY campaign_id, date_start, publisher_platform, brand
        ) AS version_count,
        MD5(
            COALESCE(campaign_id::VARCHAR, '') || '|' ||
            COALESCE(campaign_name::VARCHAR, '') || '|' ||
            COALESCE(objective::VARCHAR, '') || '|' ||
            COALESCE(account_id::VARCHAR, '') || '|' ||
            COALESCE(publisher_platform::VARCHAR, '') || '|' ||
            COALESCE(date_start::VARCHAR, '') || '|' ||
            COALESCE(spend::VARCHAR, '') || '|' ||
            COALESCE(impressions::VARCHAR, '') || '|' ||
            COALESCE(clicks::VARCHAR, '') || '|' ||
            COALESCE(reach::VARCHAR, '') || '|' ||
            COALESCE(frequency::VARCHAR, '') || '|' ||
            COALESCE(cpc::VARCHAR, '') || '|' ||
            COALESCE(cpm::VARCHAR, '') || '|' ||
            COALESCE(ctr::VARCHAR, '') || '|' ||
            COALESCE(outbound_clicks::VARCHAR, '') || '|' ||
            COALESCE(outbound_clicks_ctr::VARCHAR, '') || '|' ||
            COALESCE(video_p25_watched::VARCHAR, '') || '|' ||
            COALESCE(video_p50_watched::VARCHAR, '') || '|' ||
            COALESCE(video_p75_watched::VARCHAR, '') || '|' ||
            COALESCE(video_p100_watched::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
    FROM history
)
SELECT
    campaign_id,
    campaign_name,
    objective,
    account_id,
    publisher_platform,
    date_start::DATE AS date_nk,
    spend,
    impressions,
    clicks,
    reach,
    frequency,
    cpc,
    cpm,
    ctr,
    outbound_clicks,
    outbound_clicks_ctr,
    video_p25_watched,
    video_p50_watched,
    video_p75_watched,
    video_p100_watched,
    brand,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
