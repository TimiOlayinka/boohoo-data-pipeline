

  create view "boohoo_dwh"."rdl_shopify"."nastygal_orders__dbt_tmp" as (
    ------------------------------------------------------------------------------------------------------------------------
-- rdl_shopify.nastygal_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT id AS order_id, customer_id, created_at AS order_timestamp,
           total_price AS total_amount, financial_status AS status, gateway AS payment_method,
           discount_amount, shipping_cost, item_count, discount_codes AS promo_code, fulfillment_status AS delivery_method, source_name AS fulfilment_centre,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "boohoo_dwh"."rdl_shopify"."nastygal_orders_history"
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
       'NastyGal' AS brand, 'shopify' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
  ) ;
