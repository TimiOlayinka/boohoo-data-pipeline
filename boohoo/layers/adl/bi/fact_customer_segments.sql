--@variable "adl_bi" ${SCHEMA_ADL_BI}

------------------------------------------------------------------------------------------------------------------------
-- fact_customer_segments
-- Customer segmentation analysis for CRM dashboards
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_bi".fact_customer_segments;

CREATE TABLE "adl_bi".fact_customer_segments
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (brand)
AS
SELECT
    c.brand                                                 :: VARCHAR(50)      AS brand,
    b.brand_tier                                            :: VARCHAR(10)      AS brand_tier,
    c.customer_segment                                      :: VARCHAR(50)      AS customer_segment,
    c.gender                                                :: VARCHAR(20)      AS gender,
    c.country                                               :: VARCHAR(100)     AS country,
    COUNT(*)                                                :: INT              AS customer_count,
    COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)     :: INT              AS opted_in_count,
    ROUND(COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1)
                                                            :: DECIMAL(8,1)     AS opt_in_rate_pct,
    MIN(c.registration_date)                                :: DATE             AS earliest_registration,
    MAX(c.registration_date)                                :: DATE             AS latest_registration,
    c.ingest_date
FROM "dev_odl".dim_customers c
LEFT JOIN "dev_odl".map_brand b ON c.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 11
;

COMMIT TRANSACTION;
