--@variable "adl_bi" ${SCHEMA_ADL_BI}

------------------------------------------------------------------------------------------------------------------------
-- fact_revenue_by_brand
-- Pre-aggregated revenue metrics by brand - feeds Looker Studio
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_bi".fact_revenue_by_brand;

CREATE TABLE "adl_bi".fact_revenue_by_brand
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (brand)
AS
SELECT
    o.ingest_date,
    o.brand                                             :: VARCHAR(50)      AS brand,
    b.brand_tier                                        :: VARCHAR(10)      AS brand_tier,
    COUNT(DISTINCT o.order_nk)                          :: INT              AS total_orders,
    COUNT(DISTINCT o.customer_sk)                       :: INT              AS unique_customers,
    SUM(o.total_amount)                                 :: DECIMAL(18,2)    AS gross_revenue,
    SUM(o.net_revenue)                                  :: DECIMAL(18,2)    AS net_revenue,
    SUM(o.discount_amount)                              :: DECIMAL(18,2)    AS total_discounts,
    ROUND(AVG(o.total_amount), 2)                       :: DECIMAL(18,2)    AS avg_order_value,
    ROUND(SUM(o.discount_amount) / NULLIF(SUM(o.gross_revenue), 0) * 100, 1)
                                                        :: DECIMAL(18,1)    AS discount_rate_pct,
    SUM(o.item_count)                                   :: INT              AS total_items_sold
FROM "dev_odl".fact_orders o
LEFT JOIN "dev_odl".map_brand b ON o.brand = b.brand
GROUP BY 1, 2, 3
;

COMMIT TRANSACTION;
