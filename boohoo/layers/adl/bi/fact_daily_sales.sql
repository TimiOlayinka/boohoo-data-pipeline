--@variable "adl_bi" ${SCHEMA_ADL_BI}

------------------------------------------------------------------------------------------------------------------------
-- fact_daily_sales
-- Daily sales time series for trend analysis
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_bi".fact_daily_sales;

CREATE TABLE "adl_bi".fact_daily_sales
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (order_date)
AS
SELECT
    o.order_date                                        :: DATE             AS order_date,
    o.brand                                             :: VARCHAR(50)      AS brand,
    b.brand_tier                                        :: VARCHAR(10)      AS brand_tier,
    o.order_year                                        :: INT              AS order_year,
    o.order_month                                       :: INT              AS order_month,
    o.order_day_of_week                                 :: INT              AS order_day_of_week,
    COUNT(*)                                            :: INT              AS order_count,
    SUM(o.total_amount)                                 :: DECIMAL(18,2)    AS daily_revenue,
    SUM(o.net_revenue)                                  :: DECIMAL(18,2)    AS daily_net_revenue,
    ROUND(AVG(o.total_amount), 2)                       :: DECIMAL(18,2)    AS avg_order_value,
    SUM(o.item_count)                                   :: INT              AS items_sold,
    COUNT(DISTINCT o.customer_sk)                       :: INT              AS unique_customers
FROM "dev_odl".fact_orders o
LEFT JOIN "dev_odl".map_brand b ON o.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 6
;

COMMIT TRANSACTION;
