--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_campaign_spend_daily
-- Daily marketing spend by brand × channel with rolling averages
-- Inspired by HnB fact_campaign_spend_daily_metabase_view.sql
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_campaign_spend_daily;

CREATE TABLE "adl_digital_marketing".fact_campaign_spend_daily
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
WITH meta_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Meta Ads' :: VARCHAR(20) AS channel, 'Paid Social' :: VARCHAR(20) AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, SUM(reach) AS reach
    FROM "dev_odl".fact_meta_campaign_insights
    GROUP BY 1, 2, 3
),
google_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Google Ads' :: VARCHAR(20) AS channel, 'Paid Search' :: VARCHAR(20) AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, 0 :: BIGINT AS reach
    FROM "dev_odl".fact_google_ads_standard_campaign_performance
    GROUP BY 1, 2, 3
),
tiktok_daily AS (
    SELECT date_nk, brand, brand_tier,
           'TikTok Ads' :: VARCHAR(20) AS channel, 'Paid Social' :: VARCHAR(20) AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, SUM(reach) AS reach
    FROM "dev_odl".fact_tiktok_ad_insights
    GROUP BY 1, 2, 3
),
email_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Email' :: VARCHAR(20) AS channel, 'Email' :: VARCHAR(20) AS channel_type,
           0 :: DECIMAL(18,4) AS spend, 0 :: BIGINT AS impressions,
           SUM(clicked) :: BIGINT AS clicks, SUM(delivered) :: BIGINT AS reach
    FROM "dev_odl".fact_email_engagement
    GROUP BY 1, 2, 3
),
influencer_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Influencer' :: VARCHAR(20) AS channel, 'Influencer' :: VARCHAR(20) AS channel_type,
           SUM(cost) AS spend, SUM(impressions) AS impressions,
           SUM(link_clicks) :: BIGINT AS clicks, SUM(reach) AS reach
    FROM "dev_odl".fact_influencer_posts
    GROUP BY 1, 2, 3
),
all_channels AS (
    SELECT * FROM meta_daily
    UNION ALL SELECT * FROM google_daily
    UNION ALL SELECT * FROM tiktok_daily
    UNION ALL SELECT * FROM email_daily
    UNION ALL SELECT * FROM influencer_daily
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          :: INT              AS year,
    EXTRACT(MONTH FROM date_nk)                         :: INT              AS month,
    EXTRACT(DOW FROM date_nk)                           :: INT              AS day_of_week,
    brand,
    brand_tier,
    channel,
    channel_type,
    spend,
    impressions,
    clicks,
    reach,
    -- Calculated metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     :: DECIMAL(18,2)    AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 :: DECIMAL(18,2)    AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4)
                                                        :: DECIMAL(18,4)    AS ctr,
    -- Rolling averages
    ROUND(AVG(spend) OVER (
        PARTITION BY brand, channel ORDER BY date_nk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                                               :: DECIMAL(18,2)    AS spend_7d_avg,
    ROUND(AVG(spend) OVER (
        PARTITION BY brand, channel ORDER BY date_nk ROWS BETWEEN 27 PRECEDING AND CURRENT ROW
    ), 2)                                               :: DECIMAL(18,2)    AS spend_28d_avg
FROM all_channels
;

COMMIT TRANSACTION;
