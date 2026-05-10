------------------------------------------------------------------------------------------------------------------------
-- odl.fact_meta_campaign_insights
-- Unified Meta Ads campaign insights with surrogate keys
-- Follows HnB fact_meta_campaign_insights.sql pattern
------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
    SELECT
        campaign_id                                     AS meta_campaign_nk,
        campaign_name                                   AS meta_campaign_name,
        objective,
        account_id                                      AS meta_account_nk,
        publisher_platform,
        date_nk,
        spend                                           :: NUMERIC(18,4),
        impressions                                     :: BIGINT,
        clicks                                          :: BIGINT,
        reach                                           :: BIGINT,
        frequency                                       :: NUMERIC(18,4),
        cpc                                             :: NUMERIC(18,4),
        cpm                                             :: NUMERIC(18,4),
        ctr                                             :: NUMERIC(18,4),
        outbound_clicks                                 :: BIGINT,
        outbound_clicks_ctr                             :: NUMERIC(18,4),
        video_p25_watched                               :: BIGINT,
        video_p50_watched                               :: BIGINT,
        video_p75_watched                               :: BIGINT,
        video_p100_watched                              :: BIGINT,
        brand,
        ingest_date
    FROM {{ ref('rdl_meta_ads') }}
)
SELECT
    MD5(rd.meta_campaign_nk || '|' || rd.date_nk || '|' || rd.publisher_platform || '|' || rd.brand)
        AS meta_insight_sk,
    rd.meta_campaign_nk,
    rd.meta_campaign_name,
    dc.campaign_sk,
    dc.campaign_type,
    rd.objective,
    rd.publisher_platform,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.cpc,
    rd.cpm,
    rd.ctr,
    rd.outbound_clicks,
    rd.outbound_clicks_ctr,
    rd.video_p25_watched,
    rd.video_p50_watched,
    rd.video_p75_watched,
    rd.video_p100_watched,
    rd.brand,
    b.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM raw_data rd
LEFT JOIN {{ ref('dim_campaigns') }} dc
    ON rd.meta_campaign_nk = dc.campaign_nk AND dc.platform = 'Meta Ads' AND rd.brand = dc.brand
LEFT JOIN {{ ref('map_brand') }} b
    ON rd.brand = b.brand
