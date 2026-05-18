------------------------------------------------------------------------------------------------------------------------
-- bi.fact_marketing_summary
-- Executive summary — the "wow" table for client presentations
-- Total spend, revenue, blended ROAS, CAC, channel mix, MoM growth by brand
------------------------------------------------------------------------------------------------------------------------
WITH monthly_spend AS (
    SELECT
        DATE_TRUNC('month', date_nk)::DATE AS month_start,
        brand,
        brand_tier,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(CASE WHEN channel = 'Meta Ads' THEN spend ELSE 0 END) AS meta_spend,
        SUM(CASE WHEN channel = 'Google Ads' THEN spend ELSE 0 END) AS google_spend,
        SUM(CASE WHEN channel = 'TikTok Ads' THEN spend ELSE 0 END) AS tiktok_spend,
        SUM(CASE WHEN channel = 'Email' THEN spend ELSE 0 END) AS email_spend,
        SUM(CASE WHEN channel = 'Influencer' THEN spend ELSE 0 END) AS influencer_spend
    FROM {{ ref('fact_marketing_spend_daily') }}
    GROUP BY 1, 2, 3
),
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', date_nk)::DATE AS month_start,
        brand,
        SUM(revenue) AS total_revenue,
        SUM(transactions) AS total_orders,
        COUNT(DISTINCT session_nk) AS total_sessions,
        COUNT(DISTINCT user_pseudo_id) AS unique_visitors,
        COUNT(DISTINCT CASE WHEN transactions > 0 THEN session_nk END) AS converting_sessions
    FROM {{ ref('fact_ga4_sessions') }}
    GROUP BY 1, 2
),
monthly_email AS (
    SELECT
        DATE_TRUNC('month', date_nk)::DATE AS month_start,
        brand,
        SUM(delivered) AS emails_delivered,
        SUM(converted) AS email_conversions,
        SUM(revenue) AS email_revenue
    FROM {{ ref('fact_email_engagement') }}
    GROUP BY 1, 2
),
combined AS (
    SELECT
        s.month_start,
        EXTRACT(YEAR FROM s.month_start) AS year,
        EXTRACT(MONTH FROM s.month_start) AS month,
        s.brand,
        s.brand_tier,
        s.total_spend,
        s.total_impressions,
        s.total_clicks,
        COALESCE(r.total_revenue, 0) AS total_revenue,
        COALESCE(r.total_orders, 0) AS total_orders,
        COALESCE(r.total_sessions, 0) AS total_sessions,
        COALESCE(r.unique_visitors, 0) AS unique_visitors,
        COALESCE(e.email_revenue, 0) AS email_revenue,
        COALESCE(e.emails_delivered, 0) AS emails_delivered,
        s.meta_spend,
        s.google_spend,
        s.tiktok_spend,
        s.email_spend,
        s.influencer_spend,
        -- Channel mix percentages
        ROUND(s.meta_spend / NULLIF(s.total_spend, 0) * 100, 1) AS meta_mix_pct,
        ROUND(s.google_spend / NULLIF(s.total_spend, 0) * 100, 1) AS google_mix_pct,
        ROUND(s.tiktok_spend / NULLIF(s.total_spend, 0) * 100, 1) AS tiktok_mix_pct,
        ROUND(s.influencer_spend / NULLIF(s.total_spend, 0) * 100, 1) AS influencer_mix_pct,
        -- Blended metrics
        ROUND(COALESCE(r.total_revenue, 0) / NULLIF(s.total_spend, 0), 2) AS blended_roas,
        ROUND(s.total_spend / NULLIF(r.total_orders, 0), 2) AS customer_acquisition_cost,
        ROUND(COALESCE(r.total_revenue, 0) / NULLIF(r.total_orders, 0), 2) AS avg_order_value,
        ROUND(s.total_clicks::FLOAT / NULLIF(s.total_impressions, 0) * 100, 2) AS blended_ctr,
        ROUND(s.total_spend / NULLIF(s.total_clicks, 0), 2) AS blended_cpc,
        ROUND(COALESCE(r.converting_sessions, 0)::FLOAT / NULLIF(r.total_sessions, 0) * 100, 2) AS site_conversion_rate
    FROM monthly_spend s
    LEFT JOIN monthly_revenue r ON s.month_start = r.month_start AND s.brand = r.brand
    LEFT JOIN monthly_email e ON s.month_start = e.month_start AND s.brand = e.brand
)
SELECT
    *,
    -- Month-over-Month growth
    ROUND(
        (total_spend - LAG(total_spend) OVER (PARTITION BY brand ORDER BY month_start))
        / NULLIF(LAG(total_spend) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1)
        AS spend_mom_growth_pct,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (PARTITION BY brand ORDER BY month_start))
        / NULLIF(LAG(total_revenue) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1)
        AS revenue_mom_growth_pct,
    ROUND(
        (blended_roas - LAG(blended_roas) OVER (PARTITION BY brand ORDER BY month_start))
        / NULLIF(LAG(blended_roas) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1)
        AS roas_mom_growth_pct
FROM combined
