

  create view "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_customers__dbt_tmp" as (
    ------------------------------------------------------------------------------------------------------------------------
-- rdl_boohoo_commerce.boohoo_customers
-- Deduplicated from boohoo_customers_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT customer_id, email, first_name, last_name, phone, city, country,
           segment AS customer_segment, signup_date, gender, is_subscribed,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_customers_history"
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
       'Boohoo' AS brand, 'boohoo_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
  ) ;
