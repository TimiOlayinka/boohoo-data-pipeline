--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- dim_customers
-- Unified customer dimension across all Boohoo Group brands
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".dim_customers;

CREATE TABLE "dev_odl".dim_customers
DISTSTYLE KEY DISTKEY (customer_nk)
SORTKEY (registration_date)
AS
WITH all_customers AS (
    SELECT * FROM "rdl_boohoo_commerce".boohoo_customers
    UNION ALL SELECT * FROM "rdl_boohoo_commerce".boohoo_man_customers
    UNION ALL SELECT * FROM "rdl_salesforce_commerce".plt_customers
    UNION ALL SELECT * FROM "rdl_shopify".nastygal_customers
    UNION ALL SELECT * FROM "rdl_magento".karen_millen_customers
    UNION ALL SELECT * FROM "rdl_magento".coast_customers
    UNION ALL SELECT * FROM "rdl_oracle_commerce".debenhams_customers
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY email ORDER BY registration_date DESC, ingest_date DESC
    ) AS rnk
    FROM all_customers
)
SELECT
    MD5(customer_id || '|' || brand)                :: VARCHAR(32)      AS customer_sk,
    customer_id                                     :: VARCHAR(50)      AS customer_nk,
    email                                           :: VARCHAR(200)     AS email,
    first_name                                      :: VARCHAR(100)     AS first_name,
    last_name                                       :: VARCHAR(100)     AS last_name,
    phone                                           :: VARCHAR(50)      AS phone,
    city                                            :: VARCHAR(100)     AS city,
    country                                         :: VARCHAR(100)     AS country,
    customer_segment                                :: VARCHAR(50)      AS customer_segment,
    registration_date                               :: DATE             AS registration_date,
    gender                                          :: VARCHAR(20)      AS gender,
    is_marketing_opted_in                           :: BOOLEAN          AS is_marketing_opted_in,
    brand                                           :: VARCHAR(50)      AS brand,
    source_system                                   :: VARCHAR(50)      AS source_system,
    ingest_date,
    CURRENT_TIMESTAMP                                                   AS dwh_created_at
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
