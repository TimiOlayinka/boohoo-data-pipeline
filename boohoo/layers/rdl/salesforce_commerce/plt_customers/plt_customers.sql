--@variable "rdl_salesforce_commerce" ${SCHEMA_RDL_SALESFORCE_COMMERCE}

------------------------------------------------------------------------------------------------------------------------
-- plt_customers
-- Deduplicated PrettyLittleThing customers from plt_customers_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_salesforce_commerce".plt_customers;

CREATE TABLE "rdl_salesforce_commerce".plt_customers
DISTSTYLE KEY DISTKEY (customer_id)
SORTKEY (registration_date)
AS
WITH history AS (
    SELECT customer_no AS customer_id, email, first_name, last_name, phone_home AS phone, city,
           country_code AS country, customer_group AS customer_segment, creation_date AS signup_date, gender, email_opt_in AS is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_salesforce_commerce".plt_customers_history
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
    'PrettyLittleThing'                             :: VARCHAR(50)      AS brand,
    'salesforce_commerce'                           :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
