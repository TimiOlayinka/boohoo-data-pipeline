--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_orders
-- Unified order fact table with surrogate keys to dimensions
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_orders;

CREATE TABLE "dev_odl".fact_orders
DISTSTYLE KEY DISTKEY (order_nk)
SORTKEY (order_date)
AS
WITH all_orders AS (
    SELECT * FROM "rdl_boohoo_commerce".boohoo_orders
    UNION ALL SELECT * FROM "rdl_boohoo_commerce".boohoo_man_orders
    UNION ALL SELECT * FROM "rdl_salesforce_commerce".plt_orders
    UNION ALL SELECT * FROM "rdl_shopify".nastygal_orders
    UNION ALL SELECT * FROM "rdl_magento".karen_millen_orders
    UNION ALL SELECT * FROM "rdl_magento".coast_orders
    UNION ALL SELECT * FROM "rdl_oracle_commerce".debenhams_orders
)
SELECT
    MD5(order_id || '|' || brand)                   :: VARCHAR(32)      AS order_sk,
    order_id                                        :: VARCHAR(50)      AS order_nk,
    MD5(customer_id || '|' || brand)                :: VARCHAR(32)      AS customer_sk,
    order_timestamp                                 :: TIMESTAMP        AS order_timestamp,
    order_timestamp::DATE                           :: DATE             AS order_date,
    EXTRACT(YEAR FROM order_timestamp)              :: INT              AS order_year,
    EXTRACT(MONTH FROM order_timestamp)             :: INT              AS order_month,
    EXTRACT(DOW FROM order_timestamp)               :: INT              AS order_day_of_week,
    total_amount                                    :: DECIMAL(18,2)    AS total_amount,
    discount_amount                                 :: DECIMAL(18,2)    AS discount_amount,
    shipping_cost                                   :: DECIMAL(18,2)    AS shipping_cost,
    total_amount + shipping_cost                    :: DECIMAL(18,2)    AS gross_revenue,
    total_amount - COALESCE(discount_amount, 0)     :: DECIMAL(18,2)    AS net_revenue,
    status                                          :: VARCHAR(50)      AS status,
    payment_method                                  :: VARCHAR(50)      AS payment_method,
    promo_code                                      :: VARCHAR(50)      AS promo_code,
    delivery_method                                 :: VARCHAR(50)      AS delivery_method,
    fulfilment_centre                               :: VARCHAR(50)      AS fulfilment_centre,
    item_count                                      :: INT              AS item_count,
    brand                                           :: VARCHAR(50)      AS brand,
    source_system                                   :: VARCHAR(50)      AS source_system,
    ingest_date,
    CURRENT_TIMESTAMP                                                   AS dwh_created_at
FROM all_orders
;

COMMIT TRANSACTION;
