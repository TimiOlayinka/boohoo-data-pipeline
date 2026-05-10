------------------------------------------------------------------------------------------------------------------------
-- bi.fact_marketing_spend_daily
-- Daily marketing spend overview — spend + performance by brand × channel
-- Inspired by HnB fact_campaign_spend_daily_metabase_view.sql
------------------------------------------------------------------------------------------------------------------------
WITH meta_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Meta Ads' AS channel, 'Paid Social' AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, SUM(reach) AS reach
    FROM {{ ref('fact_meta_campaign_insights') }}
    GROUP BY 1, 2, 3
),
google_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Google Ads' AS channel, 'Paid Search' AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, 0 AS reach
    FROM {{ ref('fact_google_ads_performance') }}
    GROUP BY 1, 2, 3
),
tiktok_daily AS (
    SELECT date_nk, brand, brand_tier,
           'TikTok Ads' AS channel, 'Paid Social' AS channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions,
           SUM(clicks) AS clicks, SUM(reach) AS reach
    FROM {{ ref('fact_tiktok_ad_insights') }}
    GROUP BY 1, 2, 3
),
email_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Email' AS channel, 'Email' AS channel_type,
           0 AS spend, 0 AS impressions,
           SUM(clicked) AS clicks, SUM(delivered) AS reach
    FROM {{ ref('fact_email_engagement') }}
    GROUP BY 1, 2, 3
),
influencer_daily AS (
    SELECT date_nk, brand, brand_tier,
           'Influencer' AS channel, 'Influencer' AS channel_type,
           SUM(cost) AS spend, SUM(impressions) AS impressions,
           SUM(link_clicks) AS clicks, SUM(reach) AS reach
    FROM {{ ref('fact_influencer_performance') }}
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
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
    EXTRACT(DOW FROM date_nk)                           AS day_of_week,
    brand,
    brand_tier,
    channel,
    channel_type,
    spend,
    impressions,
    clicks,
    reach,
    -- Calculated metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4) AS ctr,
    -- Rolling averages (window functions)
    ROUND(AVG(spend) OVER (
        PARTITION BY brand, channel ORDER BY date_nk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                                               AS spend_7d_avg,
    ROUND(AVG(spend) OVER (
        PARTITION BY brand, channel ORDER BY date_nk ROWS BETWEEN 27 PRECEDING AND CURRENT ROW
    ), 2)                                               AS spend_28d_avg
FROM all_channels
