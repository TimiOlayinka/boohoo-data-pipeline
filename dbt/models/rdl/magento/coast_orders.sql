------------------------------------------------------------------------------------------------------------------------
-- rdl_magento.coast_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT increment_id AS order_id, customer_id, created_at AS order_timestamp,
           grand_total AS total_amount, status, payment_method,
           discount_amount, shipping_cost, item_count, coupon_code AS promo_code, shipping_method AS delivery_method, store_id AS fulfilment_centre,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_magento', 'coast_orders_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY increment_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT order_id, customer_id, order_timestamp::TIMESTAMP AS order_timestamp,
       total_amount, status, payment_method,
       discount_amount, shipping_cost, item_count,
       promo_code, delivery_method, fulfilment_centre,
       'Coast' AS brand, 'magento' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
