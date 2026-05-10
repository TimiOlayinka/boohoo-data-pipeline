------------------------------------------------------------------------------------------------------------------------
-- odl.fact_tiktok_ad_insights
-- Unified TikTok Ads performance with surrogate keys
-- Follows HnB fact_tiktok_ad_insights.sql pattern
------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
    SELECT
        ad_id                                           AS tiktok_ad_nk,
        advertiser_id                                   AS tiktok_advertiser_id,
        campaign_name                                   AS tiktok_campaign_name,
        objective,
        date_nk,
        spend                                           :: NUMERIC(18,4),
        impressions                                     :: BIGINT,
        clicks                                          :: BIGINT,
        reach                                           :: BIGINT,
        frequency                                       :: NUMERIC(18,4),
        ctr                                             :: NUMERIC(18,4),
        cpc                                             :: NUMERIC(18,4),
        cpm                                             :: NUMERIC(18,4),
        conversion_rate                                 :: NUMERIC(18,4),
        conversion                                      :: BIGINT,
        cost_per_conversion                             :: NUMERIC(18,4),
        purchase                                        :: BIGINT,
        video_play_actions                              :: BIGINT,
        video_watched_2s                                :: BIGINT,
        video_watched_6s                                :: BIGINT,
        video_views_p25                                 :: BIGINT,
        video_views_p50                                 :: BIGINT,
        video_views_p75                                 :: BIGINT,
        video_views_p100                                :: BIGINT,
        brand,
        ingest_date
    FROM {{ ref('rdl_tiktok_ads') }}
)
SELECT
    MD5(rd.tiktok_ad_nk || '|' || rd.date_nk || '|' || rd.brand)
                                                        AS tiktok_ad_sk,
    rd.tiktok_ad_nk,
    rd.tiktok_advertiser_id,
    rd.tiktok_campaign_name,
    rd.objective,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.ctr,
    rd.cpc,
    rd.cpm,
    rd.conversion_rate,
    rd.conversion,
    rd.cost_per_conversion,
    rd.purchase,
    rd.video_play_actions,
    rd.video_watched_2s,
    rd.video_watched_6s,
    rd.video_views_p25,
    rd.video_views_p50,
    rd.video_views_p75,
    rd.video_views_p100,
    rd.brand,
    b.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM raw_data rd
LEFT JOIN {{ ref('map_brand') }} b
    ON rd.brand = b.brand
