------------------------------------------------------------------------------------------------------------------------
-- bi.fact_channel_performance
-- Cross-channel benchmarking — normalised metrics across all marketing channels
-- Designed for client-facing channel comparison dashboards
------------------------------------------------------------------------------------------------------------------------
WITH meta AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Meta Ads' AS channel,
        'Paid Social' AS channel_type,
        SUM(spend) AS spend,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(reach) AS reach,
        0 AS conversions,
        0::NUMERIC AS revenue,
        0 AS sessions
    FROM {{ ref('fact_meta_campaign_insights') }}
    GROUP BY 1, 2, 3
),
google AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Google Ads' AS channel,
        'Paid Search' AS channel_type,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        0,
        SUM(conversions)::INT,
        SUM(conversions_value),
        0
    FROM {{ ref('fact_google_ads_performance') }}
    GROUP BY 1, 2, 3
),
tiktok AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'TikTok Ads' AS channel,
        'Paid Social' AS channel_type,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        SUM(reach),
        SUM(conversion)::INT,
        0::NUMERIC,
        0
    FROM {{ ref('fact_tiktok_ad_insights') }}
    GROUP BY 1, 2, 3
),
email AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Email' AS channel,
        'Owned' AS channel_type,
        0::NUMERIC,
        SUM(delivered)::BIGINT,
        SUM(clicked)::BIGINT,
        SUM(delivered)::BIGINT,
        SUM(converted)::INT,
        SUM(revenue),
        0
    FROM {{ ref('fact_email_engagement') }}
    GROUP BY 1, 2, 3
),
influencer AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Influencer' AS channel,
        'Earned' AS channel_type,
        SUM(cost),
        SUM(impressions),
        SUM(link_clicks)::BIGINT,
        SUM(reach),
        SUM(conversions)::INT,
        SUM(revenue_attributed),
        0
    FROM {{ ref('fact_influencer_performance') }}
    GROUP BY 1, 2, 3
),
ga4 AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Website (GA4)' AS channel,
        'All Traffic' AS channel_type,
        0::NUMERIC,
        0::BIGINT,
        0::BIGINT,
        0::BIGINT,
        SUM(transactions)::INT,
        SUM(revenue),
        COUNT(*) AS sessions
    FROM {{ ref('fact_ga4_sessions') }}
    GROUP BY 1, 2, 3
),
combined AS (
    SELECT * FROM meta UNION ALL SELECT * FROM google UNION ALL SELECT * FROM tiktok
    UNION ALL SELECT * FROM email UNION ALL SELECT * FROM influencer UNION ALL SELECT * FROM ga4
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
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
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 AS cpc,
    ROUND(clicks::FLOAT / NULLIF(impressions, 0) * 100, 4) AS ctr,
    ROUND(conversions::FLOAT / NULLIF(clicks, 0) * 100, 2) AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)            AS cost_per_conversion,
    ROUND(revenue / NULLIF(spend, 0), 2)                AS roas
FROM combined
