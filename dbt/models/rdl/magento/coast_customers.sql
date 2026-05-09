------------------------------------------------------------------------------------------------------------------------
-- rdl_magento.coast_customers
-- Deduplicated from coast_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT entity_id AS customer_id, email, firstname AS first_name, lastname AS last_name, telephone AS phone, city,
           country_id AS country, group_id AS customer_segment, created_at AS signup_date, gender, is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_magento', 'coast_customers_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY entity_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT customer_id, email, first_name, last_name, phone, city, country,
       customer_segment, signup_date::DATE AS registration_date, gender,
       is_subscribed::BOOLEAN AS is_marketing_opted_in,
       'Coast' AS brand, 'magento' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
