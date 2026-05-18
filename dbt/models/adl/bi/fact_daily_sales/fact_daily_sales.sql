------------------------------------------------------------------------------------------------------------------------
-- bi.fact_daily_sales
-- Daily sales time series for trend analysis
------------------------------------------------------------------------------------------------------------------------
SELECT
    o.order_date,
    o.brand,
    b.brand_tier,
    o.order_year,
    o.order_month,
    o.order_day_of_week,
    COUNT(*)                            AS order_count,
    SUM(o.total_amount)                 AS daily_revenue,
    SUM(o.net_revenue)                  AS daily_net_revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    SUM(o.item_count)                   AS items_sold,
    COUNT(DISTINCT o.customer_sk)       AS unique_customers
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('map_brand') }} b ON o.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 6
