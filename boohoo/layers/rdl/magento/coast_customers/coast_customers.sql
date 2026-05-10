--@variable "rdl_magento" ${SCHEMA_RDL_MAGENTO}

------------------------------------------------------------------------------------------------------------------------
-- coast_customers
-- Deduplicated Coast customers from coast_customers_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_magento".coast_customers;

CREATE TABLE "rdl_magento".coast_customers
DISTSTYLE KEY DISTKEY (customer_id)
SORTKEY (registration_date)
AS
WITH history AS (
    SELECT entity_id AS customer_id, email, firstname AS first_name, lastname AS last_name, telephone AS phone, city,
           country_id AS country, group_id AS customer_segment, created_at AS signup_date, gender, is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_magento".coast_customers_history
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
    is_subscribed::BOOLEAN                                              AS is_marketing_opted_in,
    'Coast'                                         :: VARCHAR(50)      AS brand,
    'magento'                                       :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
