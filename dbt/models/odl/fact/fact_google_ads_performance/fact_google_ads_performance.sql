------------------------------------------------------------------------------------------------------------------------
-- odl.fact_google_ads_performance
-- Unified Google Ads performance with channel grouping classification
-- Follows HnB fact_google_ads_standard_campaign_performance.sql pattern
------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
    SELECT
        customer_id                                     AS google_ads_customer_nk,
        customer_name                                   AS google_ads_customer_name,
        campaign_id                                     AS google_ads_campaign_nk,
        campaign_name                                   AS google_ads_campaign_name,
        campaign_status                                 AS google_ads_campaign_status,
        channel_type,
        ad_group_id                                     AS google_ads_ad_group_nk,
        ad_id                                           AS google_ads_ad_nk,
        date_nk,
        device,
        ad_network_type,
        cost_micros                                     :: BIGINT,
        spend                                           :: NUMERIC(18,2),
        impressions                                     :: BIGINT,
        clicks                                          :: BIGINT,
        interactions                                    :: BIGINT,
        conversions                                     :: NUMERIC(18,2),
        conversions_value                               :: NUMERIC(18,2),
        all_conversions                                 :: NUMERIC(18,2),
        all_conversions_value                           :: NUMERIC(18,2),
        video_quartile_p25_rate                         :: NUMERIC(18,2),
        video_quartile_p50_rate                         :: NUMERIC(18,2),
        video_quartile_p75_rate                         :: NUMERIC(18,2),
        video_quartile_p100_rate                        :: NUMERIC(18,2),
        brand,
        ingest_date
    FROM {{ ref('rdl_google_ads') }}
),
classified AS (
    SELECT
        *,
        CASE
            WHEN channel_type = 'PERFORMANCE_MAX'                           THEN 'Performance Max'
            WHEN channel_type = 'DEMAND_GEN'                                THEN 'Demand Gen'
            WHEN channel_type = 'VIDEO'                                     THEN 'Video / YouTube'
            WHEN channel_type = 'SHOPPING' AND google_ads_campaign_name LIKE '%Smart%'  THEN 'Smart Shopping'
            WHEN channel_type = 'SHOPPING'                                  THEN 'Shopping'
            WHEN google_ads_campaign_name LIKE '%Branded%'                  THEN 'Branded Search'
            WHEN google_ads_campaign_name LIKE '%Generic%'                  THEN 'Generic Search'
            WHEN google_ads_campaign_name LIKE '%NonBranded%'               THEN 'Generic Search'
            WHEN google_ads_campaign_name LIKE '%Competitor%'               THEN 'Competitor Search'
            ELSE 'Other Search'
        END                                             AS channel_group
    FROM raw_data
)
SELECT
    MD5(d.google_ads_ad_nk || '|' || d.date_nk || '|' || d.device || '|' || d.brand)
        AS google_ads_sk,
    d.google_ads_customer_nk,
    d.google_ads_campaign_nk,
    d.google_ads_ad_group_nk,
    d.google_ads_ad_nk,
    dc.campaign_sk,
    d.google_ads_campaign_status,
    d.channel_type,
    d.channel_group,
    d.date_nk,
    EXTRACT(YEAR FROM d.date_nk)                        AS year,
    EXTRACT(MONTH FROM d.date_nk)                       AS month,
    d.device,
    d.ad_network_type,
    d.cost_micros,
    d.spend,
    d.impressions,
    d.clicks,
    d.interactions,
    d.conversions,
    d.conversions_value,
    d.all_conversions,
    d.all_conversions_value,
    d.video_quartile_p25_rate,
    d.video_quartile_p50_rate,
    d.video_quartile_p75_rate,
    d.video_quartile_p100_rate,
    d.brand,
    b.brand_tier,
    d.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM classified d
LEFT JOIN {{ ref('dim_campaigns') }} dc
    ON d.google_ads_campaign_nk = dc.campaign_nk AND dc.platform = 'Google Ads' AND d.brand = dc.brand
LEFT JOIN {{ ref('map_brand') }} b
    ON d.brand = b.brand
