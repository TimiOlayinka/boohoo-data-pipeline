------------------------------------------------------------------------------------------------------------------------
-- bi.fact_marketing_roas
-- Return on Ad Spend by brand × channel × period
-- Links ad spend to GA4 revenue for attribution analysis
------------------------------------------------------------------------------------------------------------------------
WITH paid_spend AS (
    SELECT
        date_nk,
        brand,
        channel,
        channel_type,
        brand_tier,
        SUM(spend) AS spend,
        SUM(clicks) AS clicks
    FROM {{ ref('fact_marketing_spend_daily') }}
    WHERE channel_type IN ('Paid Social', 'Paid Search')
    GROUP BY 1, 2, 3, 4, 5
),
ga4_revenue AS (
    SELECT
        date_nk,
        brand,
        traffic_source_l2                               AS channel,
        traffic_source_l1                               AS channel_type,
        SUM(revenue)                                    AS revenue_attributed,
        SUM(transactions)                               AS orders,
        COUNT(DISTINCT session_nk)                      AS sessions,
        COUNT(DISTINCT CASE WHEN transactions > 0 THEN session_nk END) AS converting_sessions
    FROM {{ ref('fact_ga4_sessions') }}
    WHERE traffic_source_l1 IN ('Paid Search', 'Paid Social', 'Paid Shopping')
    GROUP BY 1, 2, 3, 4
)
SELECT
    COALESCE(s.date_nk, r.date_nk)                     AS date_nk,
    EXTRACT(YEAR FROM COALESCE(s.date_nk, r.date_nk))  AS year,
    EXTRACT(MONTH FROM COALESCE(s.date_nk, r.date_nk)) AS month,
    COALESCE(s.brand, r.brand)                          AS brand,
    COALESCE(s.brand_tier, '')                          AS brand_tier,
    COALESCE(s.channel, r.channel)                      AS channel,
    COALESCE(s.channel_type, r.channel_type)            AS channel_type,
    COALESCE(s.spend, 0)                                AS spend,
    COALESCE(s.clicks, 0)                               AS ad_clicks,
    COALESCE(r.sessions, 0)                             AS sessions,
    COALESCE(r.revenue_attributed, 0)                   AS revenue_attributed,
    COALESCE(r.orders, 0)                               AS orders,
    COALESCE(r.converting_sessions, 0)                  AS converting_sessions,
    -- ROAS metrics
    ROUND(COALESCE(r.revenue_attributed, 0) / NULLIF(s.spend, 0), 2)
                                                        AS roas,
    ROUND(s.spend / NULLIF(r.orders, 0), 2)             AS cost_per_acquisition,
    ROUND(s.spend / NULLIF(s.clicks, 0), 2)             AS cost_per_click,
    ROUND(r.revenue_attributed / NULLIF(r.orders, 0), 2)
                                                        AS avg_order_value,
    ROUND(r.converting_sessions::FLOAT / NULLIF(r.sessions, 0) * 100, 2)
                                                        AS session_conversion_rate
FROM paid_spend s
FULL OUTER JOIN ga4_revenue r
    ON s.date_nk = r.date_nk AND s.brand = r.brand AND s.channel = r.channel
