

  create view "boohoo_dwh"."rdl_oracle_commerce"."debenhams_orders__dbt_tmp" as (
    ------------------------------------------------------------------------------------------------------------------------
-- rdl_oracle_commerce.debenhams_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT order_number AS order_id, profile_id AS customer_id, submitted_date AS order_timestamp,
           price_total AS total_amount, state AS status, payment_type AS payment_method,
           discount_amount, shipping_cost, item_count, promotion_code AS promo_code, shipping_method AS delivery_method, site_code AS fulfilment_centre,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "boohoo_dwh"."rdl_oracle_commerce"."debenhams_orders_history"
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY order_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT order_id, customer_id, order_timestamp::TIMESTAMP AS order_timestamp,
       total_amount, status, payment_method,
       discount_amount, shipping_cost, item_count,
       promo_code, delivery_method, fulfilment_centre,
       'Debenhams' AS brand, 'oracle_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
  ) ;
