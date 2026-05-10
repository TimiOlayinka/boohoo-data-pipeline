--@variable "rdl_boohoo_commerce" ${SCHEMA_RDL_BOOHOO_COMMERCE}

------------------------------------------------------------------------------------------------------------------------
-- boohoo_man_customers
-- Deduplicated Boohoo Man customers from boohoo_man_customers_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_boohoo_commerce".boohoo_man_customers;

CREATE TABLE "rdl_boohoo_commerce".boohoo_man_customers
DISTSTYLE KEY DISTKEY (customer_id)
SORTKEY (registration_date)
AS
WITH history AS (
    SELECT customer_id, email, first_name, last_name, phone, city, country,
           data."segment" AS customer_segment, signup_date, data."gender", data."is_subscribed",
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_boohoo_commerce".boohoo_man_customers_history
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
    'Boohoo Man'                                    :: VARCHAR(50)      AS brand,
    'boohoo_commerce'                               :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
