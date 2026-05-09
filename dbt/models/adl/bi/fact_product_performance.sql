------------------------------------------------------------------------------------------------------------------------
-- bi.fact_product_performance
-- Product performance metrics for merchandising dashboards
------------------------------------------------------------------------------------------------------------------------
SELECT
    p.brand,
    b.brand_tier,
    p.category,
    p.subcategory,
    p.stock_status,
    COUNT(DISTINCT p.product_nk)                AS sku_count,
    ROUND(AVG(p.current_price), 2)              AS avg_selling_price,
    ROUND(AVG(p.rrp), 2)                        AS avg_rrp,
    ROUND(AVG(p.margin_pct), 1)                 AS avg_margin_pct,
    ROUND(AVG(p.discount_pct), 1)               AS avg_discount_pct,
    COUNT(CASE WHEN p.is_active THEN 1 END)     AS active_skus,
    COUNT(CASE WHEN NOT p.is_active THEN 1 END) AS inactive_skus,
    p.ingest_date
FROM {{ ref('dim_products') }} p
LEFT JOIN {{ ref('map_brand') }} b ON p.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 13
