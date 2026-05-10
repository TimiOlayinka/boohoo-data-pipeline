--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_campaign_performance
-- Campaign-level deep-dive — top/bottom campaigns by spend, ROAS, conversions
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_campaign_performance;

CREATE TABLE "adl_digital_marketing".fact_campaign_performance
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
WITH meta_campaigns AS (
    SELECT
        date_nk, brand, brand_tier,
        meta_campaign_name                              :: VARCHAR(5000)    AS campaign_name,
        campaign_type                                   :: VARCHAR(50)      AS campaign_type,
        'Meta Ads'                                      :: VARCHAR(20)      AS channel,
        objective                                       :: VARCHAR(50)      AS objective,
        SUM(spend) AS spend, SUM(impressions) AS impressions,
        SUM(clicks) AS clicks, SUM(reach) AS reach,
        0 :: INT AS conversions, 0 :: DECIMAL(18,2) AS conversions_value
    FROM "dev_odl".fact_meta_campaign_insights
    GROUP BY 1, 2, 3, 4, 5, 7
),
google_campaigns AS (
    SELECT
        date_nk, brand, brand_tier,
        google_ads_campaign_name                        :: VARCHAR(5000)    AS campaign_name,
        channel_group                                   :: VARCHAR(50)      AS campaign_type,
        'Google Ads'                                    :: VARCHAR(20)      AS channel,
        channel_type                                    :: VARCHAR(50)      AS objective,
        SUM(spend), SUM(impressions), SUM(clicks), 0 :: BIGINT,
        SUM(conversions) :: INT, SUM(conversions_value)
    FROM "dev_odl".fact_google_ads_standard_campaign_performance
    GROUP BY 1, 2, 3, 4, 5, 7
),
tiktok_campaigns AS (
    SELECT
        date_nk, brand, brand_tier,
        tiktok_campaign_name                            :: VARCHAR(5000)    AS campaign_name,
        'TikTok'                                        :: VARCHAR(50)      AS campaign_type,
        'TikTok Ads'                                    :: VARCHAR(20)      AS channel,
        objective                                       :: VARCHAR(50)      AS objective,
        SUM(spend), SUM(impressions), SUM(clicks), SUM(reach),
        SUM(conversion) :: INT, 0 :: DECIMAL(18,2)
    FROM "dev_odl".fact_tiktok_ad_insights
    GROUP BY 1, 2, 3, 4, 5, 7
),
all_campaigns AS (
    SELECT * FROM meta_campaigns
    UNION ALL SELECT * FROM google_campaigns
    UNION ALL SELECT * FROM tiktok_campaigns
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          :: INT              AS year,
    EXTRACT(MONTH FROM date_nk)                         :: INT              AS month,
    brand,
    brand_tier,
    campaign_name,
    campaign_type,
    channel,
    objective,
    spend,
    impressions,
    clicks,
    reach,
    conversions,
    conversions_value,
    -- Performance metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     :: DECIMAL(18,2)    AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 :: DECIMAL(18,2)    AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4)
                                                        :: DECIMAL(18,4)    AS ctr,
    ROUND(conversions::FLOAT / NULLIF(clicks, 0) * 100, 2)
                                                        :: DECIMAL(18,2)    AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)            :: DECIMAL(18,2)    AS cost_per_conversion,
    ROUND(conversions_value / NULLIF(spend, 0), 2)      :: DECIMAL(18,2)    AS roas
FROM all_campaigns
;

COMMIT TRANSACTION;
