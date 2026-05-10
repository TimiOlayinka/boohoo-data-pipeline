--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_google_ads_standard_campaign_performance
-- Google Ads performance with channel grouping classification
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_google_ads_standard_campaign_performance;

CREATE TABLE "dev_odl".fact_google_ads_standard_campaign_performance
DISTSTYLE KEY DISTKEY (google_ads_ad_nk)
SORTKEY (date_nk)
AS
WITH raw_data AS (
    SELECT
        customer_id                                     :: VARCHAR(50)      AS google_ads_customer_nk,
        customer_name                                   :: VARCHAR(200)     AS google_ads_customer_name,
        campaign_id                                     :: VARCHAR(50)      AS google_ads_campaign_nk,
        campaign_name                                   :: VARCHAR(5000)    AS google_ads_campaign_name,
        campaign_status                                 :: VARCHAR(20)      AS google_ads_campaign_status,
        channel_type                                    :: VARCHAR(50)      AS channel_type,
        ad_group_id                                     :: VARCHAR(50)      AS google_ads_ad_group_nk,
        ad_id                                           :: VARCHAR(50)      AS google_ads_ad_nk,
        date_nk                                         :: DATE             AS date_nk,
        device                                          :: VARCHAR(20)      AS device,
        ad_network_type                                 :: VARCHAR(50)      AS ad_network_type,
        cost_micros                                     :: BIGINT           AS cost_micros,
        spend                                           :: DECIMAL(18,2)    AS spend,
        impressions                                     :: BIGINT           AS impressions,
        clicks                                          :: BIGINT           AS clicks,
        interactions                                    :: BIGINT           AS interactions,
        conversions                                     :: DECIMAL(18,2)    AS conversions,
        conversions_value                               :: DECIMAL(18,2)    AS conversions_value,
        all_conversions                                 :: DECIMAL(18,2)    AS all_conversions,
        all_conversions_value                           :: DECIMAL(18,2)    AS all_conversions_value,
        video_quartile_p25_rate                         :: DECIMAL(18,2)    AS video_quartile_p25_rate,
        video_quartile_p50_rate                         :: DECIMAL(18,2)    AS video_quartile_p50_rate,
        video_quartile_p75_rate                         :: DECIMAL(18,2)    AS video_quartile_p75_rate,
        video_quartile_p100_rate                        :: DECIMAL(18,2)    AS video_quartile_p100_rate,
        brand                                           :: VARCHAR(50)      AS brand,
        ingest_date
    FROM "rdl_google_ads".standard_campaigns
),
classified AS (
    SELECT *,
        CASE
            WHEN channel_type = 'PERFORMANCE_MAX'                                       THEN 'Performance Max'
            WHEN channel_type = 'DEMAND_GEN'                                            THEN 'Demand Gen'
            WHEN channel_type = 'VIDEO'                                                 THEN 'Video / YouTube'
            WHEN channel_type = 'SHOPPING' AND google_ads_campaign_name LIKE '%Smart%'  THEN 'Smart Shopping'
            WHEN channel_type = 'SHOPPING'                                              THEN 'Shopping'
            WHEN google_ads_campaign_name LIKE '%Branded%'                              THEN 'Branded Search'
            WHEN google_ads_campaign_name LIKE '%Generic%'                              THEN 'Generic Search'
            WHEN google_ads_campaign_name LIKE '%NonBranded%'                           THEN 'Generic Search'
            WHEN google_ads_campaign_name LIKE '%Competitor%'                           THEN 'Competitor Search'
            ELSE 'Other Search'
        END                                             :: VARCHAR(50)      AS channel_group
    FROM raw_data
)
SELECT
    MD5(d.google_ads_ad_nk || '|' || d.date_nk || '|' || d.device || '|' || d.brand)
                                                        :: VARCHAR(32)      AS google_ads_sk,
    d.google_ads_customer_nk,
    d.google_ads_campaign_nk,
    d.google_ads_ad_group_nk,
    d.google_ads_ad_nk,
    dc.campaign_sk,
    d.google_ads_campaign_status,
    d.channel_type,
    d.channel_group,
    d.date_nk,
    EXTRACT(YEAR FROM d.date_nk)                        :: INT              AS year,
    EXTRACT(MONTH FROM d.date_nk)                       :: INT              AS month,
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
    mb.brand_tier,
    d.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM classified d
LEFT JOIN "dev_odl".dim_campaigns dc
    ON d.google_ads_campaign_nk = dc.campaign_nk AND dc.platform = 'Google Ads' AND d.brand = dc.brand
LEFT JOIN "dev_odl".map_brand mb
    ON d.brand = mb.brand
;

COMMIT TRANSACTION;
