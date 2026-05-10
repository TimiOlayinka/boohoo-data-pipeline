--@variable "adl_bi" ${SCHEMA_ADL_BI}

------------------------------------------------------------------------------------------------------------------------
-- fact_channel_performance
-- Cross-channel benchmarking — normalised metrics across all marketing channels
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_bi".fact_channel_performance;

CREATE TABLE "adl_bi".fact_channel_performance
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
WITH meta AS (
    SELECT date_nk, brand, brand_tier,
           'Meta Ads' :: VARCHAR(20) AS channel, 'Paid Social' :: VARCHAR(20) AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, SUM(reach) AS reach, 0 :: INT AS conversions,
           0 :: DECIMAL(18,2) AS revenue, 0 :: INT AS sessions
    FROM "dev_odl".fact_meta_campaign_insights GROUP BY 1, 2, 3
),
google AS (
    SELECT date_nk, brand, brand_tier,
           'Google Ads' :: VARCHAR(20), 'Paid Search' :: VARCHAR(20),
           SUM(spend), SUM(impressions), SUM(clicks), 0 :: BIGINT,
           SUM(conversions) :: INT, SUM(conversions_value), 0 :: INT
    FROM "dev_odl".fact_google_ads_standard_campaign_performance GROUP BY 1, 2, 3
),
tiktok AS (
    SELECT date_nk, brand, brand_tier,
           'TikTok Ads' :: VARCHAR(20), 'Paid Social' :: VARCHAR(20),
           SUM(spend), SUM(impressions), SUM(clicks), SUM(reach),
           SUM(conversion) :: INT, 0 :: DECIMAL(18,2), 0 :: INT
    FROM "dev_odl".fact_tiktok_ad_insights GROUP BY 1, 2, 3
),
email AS (
    SELECT date_nk, brand, brand_tier,
           'Email' :: VARCHAR(20), 'Owned' :: VARCHAR(20),
           0 :: DECIMAL(18,4), SUM(delivered) :: BIGINT, SUM(clicked) :: BIGINT, SUM(delivered) :: BIGINT,
           SUM(converted) :: INT, SUM(revenue), 0 :: INT
    FROM "dev_odl".fact_email_engagement GROUP BY 1, 2, 3
),
influencer AS (
    SELECT date_nk, brand, brand_tier,
           'Influencer' :: VARCHAR(20), 'Earned' :: VARCHAR(20),
           SUM(cost), SUM(impressions), SUM(link_clicks) :: BIGINT, SUM(reach),
           SUM(conversions) :: INT, SUM(revenue_attributed), 0 :: INT
    FROM "dev_odl".fact_influencer_posts GROUP BY 1, 2, 3
),
ga4 AS (
    SELECT date_nk, brand, brand_tier,
           'Website (GA4)' :: VARCHAR(20), 'All Traffic' :: VARCHAR(20),
           0 :: DECIMAL(18,4), 0 :: BIGINT, 0 :: BIGINT, 0 :: BIGINT,
           SUM(transactions) :: INT, SUM(revenue), COUNT(*) :: INT
    FROM "dev_odl".fact_ga4_sessions GROUP BY 1, 2, 3
),
combined AS (
    SELECT * FROM meta UNION ALL SELECT * FROM google UNION ALL SELECT * FROM tiktok
    UNION ALL SELECT * FROM email UNION ALL SELECT * FROM influencer UNION ALL SELECT * FROM ga4
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          :: INT          AS year,
    EXTRACT(MONTH FROM date_nk)                         :: INT          AS month,
    brand,
    brand_tier,
    channel,
    channel_type,
    spend,
    impressions,
    clicks,
    reach,
    conversions,
    revenue,
    sessions,
    -- Normalised metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     :: DECIMAL(18,2) AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 :: DECIMAL(18,2) AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4)
                                                        :: DECIMAL(18,4) AS ctr,
    ROUND(conversions::FLOAT / NULLIF(clicks, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)            :: DECIMAL(18,2) AS cost_per_conversion,
    ROUND(revenue / NULLIF(spend, 0), 2)                :: DECIMAL(18,2) AS roas
FROM combined
;

COMMIT TRANSACTION;
