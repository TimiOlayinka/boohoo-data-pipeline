-- ============================================================================
-- Data Architecture Portfolio — Analytical Views
-- ============================================================================
-- These views power the Google Looker Studio dashboards.
-- They pre-aggregate data to minimize Redshift compute on each query.
-- ============================================================================


-- ============================================================================
-- VIEW: Daily Revenue Summary
-- Powers: Executive Dashboard — revenue trend line, daily KPIs
-- ============================================================================
CREATE OR REPLACE VIEW v_daily_revenue AS
SELECT
    o.order_date,
    EXTRACT(YEAR FROM o.order_date)             AS order_year,
    EXTRACT(MONTH FROM o.order_date)            AS order_month,
    EXTRACT(DOW FROM o.order_date)              AS day_of_week,
    TO_CHAR(o.order_date, 'Day')                AS day_name,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    COUNT(DISTINCT o.customer_id)               AS unique_customers,
    SUM(o.total_amount)                         AS gross_revenue,
    SUM(o.discount_amount)                      AS total_discounts,
    SUM(o.total_amount - o.discount_amount)     AS net_revenue,
    SUM(o.shipping_cost)                        AS total_shipping,
    AVG(o.total_amount)                         AS avg_order_value,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END)  AS cancelled_orders,
    SUM(CASE WHEN o.status = 'Returned' THEN 1 ELSE 0 END)   AS returned_orders
FROM fact_orders o
WHERE o.status NOT IN ('Cancelled')
GROUP BY o.order_date
ORDER BY o.order_date;


-- ============================================================================
-- VIEW: Monthly Trends
-- Powers: Executive Dashboard — MoM growth, seasonality charts
-- ============================================================================
CREATE OR REPLACE VIEW v_monthly_trends AS
SELECT
    EXTRACT(YEAR FROM o.order_date)                             AS order_year,
    EXTRACT(MONTH FROM o.order_date)                            AS order_month,
    TO_CHAR(o.order_date, 'YYYY-MM')                            AS year_month,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    COUNT(DISTINCT o.customer_id)                               AS unique_customers,
    SUM(o.total_amount)                                         AS gross_revenue,
    SUM(o.total_amount - o.discount_amount)                     AS net_revenue,
    AVG(o.total_amount)                                         AS avg_order_value,
    COUNT(DISTINCT CASE
        WHEN c.signup_date >= DATE_TRUNC('month', o.order_date)
        THEN c.customer_id
    END)                                                        AS new_customers,
    SUM(oi.quantity)                                             AS total_units_sold
FROM fact_orders o
JOIN dim_customers c ON o.customer_id = c.customer_id
JOIN fact_order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date),
    TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY year_month;


-- ============================================================================
-- VIEW: Customer Segments
-- Powers: Customer Analytics — segmentation pie chart, segment KPIs
-- ============================================================================
CREATE OR REPLACE VIEW v_customer_segments AS
SELECT
    c.segment,
    c.country,
    COUNT(DISTINCT c.customer_id)                               AS customer_count,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    COALESCE(SUM(o.total_amount), 0)                            AS total_revenue,
    COALESCE(AVG(o.total_amount), 0)                            AS avg_order_value,
    COALESCE(
        SUM(o.total_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0),
        0
    )                                                           AS revenue_per_customer,
    MIN(o.order_date)                                           AS first_order_date,
    MAX(o.order_date)                                           AS last_order_date
FROM dim_customers c
LEFT JOIN fact_orders o ON c.customer_id = o.customer_id
    AND o.status NOT IN ('Cancelled')
GROUP BY c.segment, c.country
ORDER BY total_revenue DESC;


-- ============================================================================
-- VIEW: Top Customers (by Lifetime Value)
-- Powers: Customer Analytics — top customers table
-- ============================================================================
CREATE OR REPLACE VIEW v_top_customers AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name                         AS customer_name,
    c.email,
    c.city,
    c.country,
    c.segment,
    c.signup_date,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    SUM(o.total_amount)                                         AS lifetime_value,
    AVG(o.total_amount)                                         AS avg_order_value,
    MIN(o.order_date)                                           AS first_order,
    MAX(o.order_date)                                           AS last_order,
    DATEDIFF(day, MIN(o.order_date), MAX(o.order_date))         AS customer_tenure_days,
    SUM(oi.quantity)                                             AS total_items_purchased
FROM dim_customers c
JOIN fact_orders o ON c.customer_id = o.customer_id
JOIN fact_order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY
    c.customer_id, c.first_name, c.last_name, c.email,
    c.city, c.country, c.segment, c.signup_date
ORDER BY lifetime_value DESC
LIMIT 500;


-- ============================================================================
-- VIEW: Product Performance
-- Powers: Product Dashboard — category breakdown, top sellers
-- ============================================================================
CREATE OR REPLACE VIEW v_product_performance AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.unit_price                                                AS list_price,
    p.cost_price,
    (p.unit_price - p.cost_price)                               AS margin_per_unit,
    COUNT(DISTINCT oi.order_id)                                 AS orders_containing,
    SUM(oi.quantity)                                             AS total_units_sold,
    SUM(oi.line_total)                                          AS total_revenue,
    SUM(oi.quantity * p.cost_price)                              AS total_cost,
    SUM(oi.line_total) - SUM(oi.quantity * p.cost_price)        AS gross_profit,
    CASE
        WHEN SUM(oi.line_total) > 0
        THEN (SUM(oi.line_total) - SUM(oi.quantity * p.cost_price))
             / SUM(oi.line_total) * 100
        ELSE 0
    END                                                         AS gross_margin_pct,
    AVG(oi.discount_pct)                                        AS avg_discount_pct
FROM dim_products p
JOIN fact_order_items oi ON p.product_id = oi.product_id
JOIN fact_orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY
    p.product_id, p.product_name, p.category, p.subcategory,
    p.unit_price, p.cost_price
ORDER BY total_revenue DESC;


-- ============================================================================
-- VIEW: Category Performance (aggregated)
-- Powers: Product Dashboard — category-level bar charts, heatmaps
-- ============================================================================
CREATE OR REPLACE VIEW v_category_performance AS
SELECT
    p.category,
    p.subcategory,
    EXTRACT(YEAR FROM o.order_date)                             AS order_year,
    EXTRACT(MONTH FROM o.order_date)                            AS order_month,
    TO_CHAR(o.order_date, 'YYYY-MM')                            AS year_month,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    SUM(oi.quantity)                                             AS total_units,
    SUM(oi.line_total)                                          AS total_revenue,
    SUM(oi.quantity * p.cost_price)                              AS total_cost,
    SUM(oi.line_total) - SUM(oi.quantity * p.cost_price)        AS gross_profit
FROM dim_products p
JOIN fact_order_items oi ON p.product_id = oi.product_id
JOIN fact_orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY
    p.category, p.subcategory,
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date),
    TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY p.category, year_month;


-- ============================================================================
-- VIEW: Revenue by Geography
-- Powers: Executive Dashboard — geographic map/heatmap
-- ============================================================================
CREATE OR REPLACE VIEW v_revenue_by_geography AS
SELECT
    c.country,
    c.city,
    COUNT(DISTINCT c.customer_id)                               AS customer_count,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    SUM(o.total_amount)                                         AS total_revenue,
    AVG(o.total_amount)                                         AS avg_order_value
FROM dim_customers c
JOIN fact_orders o ON c.customer_id = o.customer_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY c.country, c.city
ORDER BY total_revenue DESC;


-- ============================================================================
-- VIEW: Order Status Distribution
-- Powers: Executive Dashboard — status breakdown donut chart
-- ============================================================================
CREATE OR REPLACE VIEW v_order_status AS
SELECT
    status,
    EXTRACT(YEAR FROM order_date)                               AS order_year,
    EXTRACT(MONTH FROM order_date)                              AS order_month,
    TO_CHAR(order_date, 'YYYY-MM')                              AS year_month,
    COUNT(*)                                                    AS order_count,
    SUM(total_amount)                                           AS total_value
FROM fact_orders
GROUP BY
    status,
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date),
    TO_CHAR(order_date, 'YYYY-MM')
ORDER BY year_month, status;
