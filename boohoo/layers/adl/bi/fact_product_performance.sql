--@variable "adl_bi" ${SCHEMA_ADL_BI}

------------------------------------------------------------------------------------------------------------------------
-- fact_product_performance
-- Product performance metrics for merchandising dashboards
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_bi".fact_product_performance;

CREATE TABLE "adl_bi".fact_product_performance
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (brand)
AS
SELECT
    p.brand                                             :: VARCHAR(50)      AS brand,
    b.brand_tier                                        :: VARCHAR(10)      AS brand_tier,
    p.category                                          :: VARCHAR(100)     AS category,
    p.subcategory                                       :: VARCHAR(100)     AS subcategory,
    p.stock_status                                      :: VARCHAR(50)      AS stock_status,
    COUNT(DISTINCT p.product_nk)                        :: INT              AS sku_count,
    ROUND(AVG(p.current_price), 2)                      :: DECIMAL(18,2)    AS avg_selling_price,
    ROUND(AVG(p.rrp), 2)                                :: DECIMAL(18,2)    AS avg_rrp,
    ROUND(AVG(p.margin_pct), 1)                         :: DECIMAL(18,1)    AS avg_margin_pct,
    ROUND(AVG(p.discount_pct), 1)                       :: DECIMAL(18,1)    AS avg_discount_pct,
    COUNT(CASE WHEN p.is_active THEN 1 END)             :: INT              AS active_skus,
    COUNT(CASE WHEN NOT p.is_active THEN 1 END)         :: INT              AS inactive_skus,
    p.ingest_date
FROM "dev_odl".dim_products p
LEFT JOIN "dev_odl".map_brand b ON p.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 13
;

COMMIT TRANSACTION;
