------------------------------------------------------------------------------------------------------------------------
-- bi.fact_influencer_roi
-- Influencer marketing ROI dashboard — creator performance by tier, platform, brand
------------------------------------------------------------------------------------------------------------------------
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk) AS year,
    EXTRACT(MONTH FROM date_nk) AS month,
    brand, brand_tier,
    creator_handle, creator_name, creator_tier, creator_followers,
    platform, content_type, category_promoted, promo_code,
    cost, reach, impressions,
    likes, comments, shares, saves, total_engagement, engagement_rate,
    link_clicks, conversions, revenue_attributed,
    cost_per_engagement, cost_per_click, cost_per_conversion,
    roi, emv, emv_ratio,
    ROUND(total_engagement::FLOAT / NULLIF(creator_followers, 0) * 100, 2) AS follower_engagement_rate,
    ROUND(revenue_attributed / NULLIF(reach, 0) * 1000, 2) AS revenue_per_1k_reach,
    ROUND(link_clicks::FLOAT / NULLIF(impressions, 0) * 100, 2) AS link_click_rate
FROM {{ ref('fact_influencer_performance') }}
