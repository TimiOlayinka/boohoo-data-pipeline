------------------------------------------------------------------------------------------------------------------------
-- bi.fact_revenue_by_brand
-- Pre-aggregated revenue metrics by brand - feeds Looker Studio
------------------------------------------------------------------------------------------------------------------------
SELECT
    o.ingest_date,
    o.brand,
    b.brand_tier,
    COUNT(DISTINCT o.order_nk)          AS total_orders,
    COUNT(DISTINCT o.customer_sk)       AS unique_customers,
    SUM(o.total_amount)                 AS gross_revenue,
    SUM(o.net_revenue)                  AS net_revenue,
    SUM(o.discount_amount)              AS total_discounts,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    ROUND(SUM(o.discount_amount) / NULLIF(SUM(o.gross_revenue), 0) * 100, 1) AS discount_rate_pct,
    SUM(o.item_count)                   AS total_items_sold
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('map_brand') }} b ON o.brand = b.brand
GROUP BY 1, 2, 3
