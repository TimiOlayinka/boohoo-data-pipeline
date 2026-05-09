------------------------------------------------------------------------------------------------------------------------
-- rdl_oracle_commerce.debenhams_customers
-- Deduplicated from debenhams_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT profile_id AS customer_id, email_address AS email, first_name, last_name, phone_number AS phone, city,
           country, customer_segment, registration_date AS signup_date, gender, receive_email AS is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_oracle_commerce', 'debenhams_customers_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY customer_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT customer_id, email, first_name, last_name, phone, city, country,
       customer_segment, signup_date::DATE AS registration_date, gender,
       is_subscribed::BOOLEAN AS is_marketing_opted_in,
       'Debenhams' AS brand, 'oracle_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
