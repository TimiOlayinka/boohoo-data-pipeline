------------------------------------------------------------------------------------------------------------------------
-- rdl_salesforce_commerce.plt_customers
-- Deduplicated from plt_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT customer_no AS customer_id, email, first_name, last_name, phone_home AS phone, city,
           country_code AS country, customer_group AS customer_segment, creation_date AS signup_date, gender, email_opt_in AS is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_salesforce_commerce', 'plt_customers_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY customer_no ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT customer_id, email, first_name, last_name, phone, city, country,
       customer_segment, signup_date::DATE AS registration_date, gender,
       is_subscribed::BOOLEAN AS is_marketing_opted_in,
       'PrettyLittleThing' AS brand, 'salesforce_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
