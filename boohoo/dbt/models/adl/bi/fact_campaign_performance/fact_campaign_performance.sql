------------------------------------------------------------------------------------------------------------------------
-- bi.fact_campaign_performance
-- Campaign-level deep-dive — top/bottom campaigns by spend, ROAS, conversions
-- Feeds the campaign drill-down dashboard
------------------------------------------------------------------------------------------------------------------------
WITH meta_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        meta_campaign_name                              AS campaign_name,
        campaign_type,
        'Meta Ads'                                      AS channel,
        objective,
        SUM(spend) AS spend,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(reach) AS reach,
        0 AS conversions,
        0::NUMERIC AS conversions_value
    FROM {{ ref('fact_meta_campaign_insights') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
google_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        google_ads_campaign_name                        AS campaign_name,
        channel_group                                   AS campaign_type,
        'Google Ads'                                    AS channel,
        channel_type                                    AS objective,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        0,
        SUM(conversions)::INT,
        SUM(conversions_value)
    FROM {{ ref('fact_google_ads_performance') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
tiktok_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        tiktok_campaign_name                            AS campaign_name,
        'TikTok'                                        AS campaign_type,
        'TikTok Ads'                                    AS channel,
        objective,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        SUM(reach),
        SUM(conversion)::INT,
        0::NUMERIC
    FROM {{ ref('fact_tiktok_ad_insights') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
all_campaigns AS (
    SELECT * FROM meta_campaigns
    UNION ALL SELECT * FROM google_campaigns
    UNION ALL SELECT * FROM tiktok_campaigns
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
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
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4) AS ctr,
    ROUND(conversions::FLOAT / NULLIF(clicks, 0) * 100, 2) AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)            AS cost_per_conversion,
    ROUND(conversions_value / NULLIF(spend, 0), 2)      AS roas
FROM all_campaigns
