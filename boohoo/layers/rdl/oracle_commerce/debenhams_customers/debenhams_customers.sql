--@variable "rdl_oracle_commerce" ${SCHEMA_RDL_ORACLE_COMMERCE}

------------------------------------------------------------------------------------------------------------------------
-- debenhams_customers
-- Deduplicated Debenhams customers from debenhams_customers_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_oracle_commerce".debenhams_customers;

CREATE TABLE "rdl_oracle_commerce".debenhams_customers
DISTSTYLE KEY DISTKEY (customer_id)
SORTKEY (registration_date)
AS
WITH history AS (
    SELECT profile_id AS customer_id, email_address AS email, first_name, last_name, phone_number AS phone, city,
           country, customer_segment, registration_date AS signup_date, gender, receive_email AS is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_oracle_commerce".debenhams_customers_history
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
    'Debenhams'                                     :: VARCHAR(50)      AS brand,
    'oracle_commerce'                               :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
