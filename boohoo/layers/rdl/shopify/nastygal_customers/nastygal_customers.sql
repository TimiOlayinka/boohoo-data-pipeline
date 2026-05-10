--@variable "rdl_shopify" ${SCHEMA_RDL_SHOPIFY}

------------------------------------------------------------------------------------------------------------------------
-- nastygal_customers
-- Deduplicated NastyGal customers from nastygal_customers_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_shopify".nastygal_customers;

CREATE TABLE "rdl_shopify".nastygal_customers
DISTSTYLE KEY DISTKEY (customer_id)
SORTKEY (registration_date)
AS
WITH history AS (
    SELECT id AS customer_id, email, first_name, last_name, phone, city,
           country, tags AS customer_segment, created_at AS signup_date, NULL AS gender, accepts_marketing AS is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_shopify".nastygal_customers_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY customer_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    customer_id                                     :: VARCHAR(50)      AS customer_id,
    email                                           :: VARCHAR(200)     AS email,
    first_name                                      :: VARCHAR(100)     AS first_name,
    last_name                                       :: VARCHAR(100)     AS last_name,
    phone                                           :: VARCHAR(50)      AS phone,
    city                                            :: VARCHAR(100)     AS city,
    country                                         :: VARCHAR(100)     AS country,
    customer_segment                                :: VARCHAR(50)      AS customer_segment,
    signup_date::DATE                                                   AS registration_date,
    gender                                          :: VARCHAR(20)      AS gender,
    CASE WHEN is_subscribed IN ('true', 'True', '1', 'yes') THEN TRUE ELSE FALSE END AS is_marketing_opted_in,
    'NastyGal'                                      :: VARCHAR(50)      AS brand,
    'shopify'                                       :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
