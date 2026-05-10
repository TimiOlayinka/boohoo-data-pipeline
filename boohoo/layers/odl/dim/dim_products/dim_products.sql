--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- dim_products
-- Unified product dimension with calculated margin metrics
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".dim_products;

CREATE TABLE "dev_odl".dim_products
DISTSTYLE KEY DISTKEY (product_nk)
SORTKEY (category)
AS
WITH all_products AS (
    SELECT * FROM "rdl_boohoo_commerce".boohoo_products
    UNION ALL SELECT * FROM "rdl_boohoo_commerce".boohoo_man_products
    UNION ALL SELECT * FROM "rdl_salesforce_commerce".plt_products
    UNION ALL SELECT * FROM "rdl_shopify".nastygal_products
    UNION ALL SELECT * FROM "rdl_magento".karen_millen_products
    UNION ALL SELECT * FROM "rdl_magento".coast_products
    UNION ALL SELECT * FROM "rdl_oracle_commerce".debenhams_products
)
SELECT
    MD5(product_id || '|' || brand)                 :: VARCHAR(32)      AS product_sk,
    product_id                                      :: VARCHAR(50)      AS product_nk,
    product_name                                    :: VARCHAR(500)     AS product_name,
    colour                                          :: VARCHAR(100)     AS colour,
    category                                        :: VARCHAR(100)     AS category,
    subcategory                                     :: VARCHAR(100)     AS subcategory,
    current_price                                   :: DECIMAL(18,2)    AS current_price,
    cost_price                                      :: DECIMAL(18,2)    AS cost_price,
    rrp                                             :: DECIMAL(18,2)    AS rrp,
    CASE WHEN rrp > 0 THEN ROUND((1 - current_price / rrp) * 100, 1) ELSE 0 END
                                                    :: DECIMAL(18,1)    AS discount_pct,
    ROUND(current_price - cost_price, 2)            :: DECIMAL(18,2)    AS margin,
    CASE WHEN current_price > 0 THEN ROUND((current_price - cost_price) / current_price * 100, 1) ELSE 0 END
                                                    :: DECIMAL(18,1)    AS margin_pct,
    material                                        :: VARCHAR(100)     AS material,
    season                                          :: VARCHAR(50)      AS season,
    is_active                                       :: BOOLEAN          AS is_active,
    stock_status                                    :: VARCHAR(50)      AS stock_status,
    brand                                           :: VARCHAR(50)      AS brand,
    source_system                                   :: VARCHAR(50)      AS source_system,
    ingest_date,
    CURRENT_TIMESTAMP                                                   AS dwh_created_at
FROM all_products
;

COMMIT TRANSACTION;
