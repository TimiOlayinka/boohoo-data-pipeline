------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.meta_ads
-- Deduplicated Meta Ads campaign insights from meta_ads_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
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
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, date_start, publisher_platform, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
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
    ingest_ts
FROM dedup WHERE rnk = 1
