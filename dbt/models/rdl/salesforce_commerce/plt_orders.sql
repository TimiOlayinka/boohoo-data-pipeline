------------------------------------------------------------------------------------------------------------------------
-- rdl_salesforce_commerce.plt_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT order_no AS order_id, customer_no AS customer_id, creation_date AS order_timestamp,
           order_total AS total_amount, status, payment_instrument AS payment_method,
           discount_amount, shipping_cost, item_count, coupon_code AS promo_code, shipment_method_id AS delivery_method, site_id AS fulfilment_centre,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_salesforce_commerce', 'plt_orders_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY order_no ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT order_id, customer_id, order_timestamp::TIMESTAMP AS order_timestamp,
       total_amount, status, payment_method,
       discount_amount, shipping_cost, item_count,
       promo_code, delivery_method, fulfilment_centre,
       'PrettyLittleThing' AS brand, 'salesforce_commerce' AS source_system,
       ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
