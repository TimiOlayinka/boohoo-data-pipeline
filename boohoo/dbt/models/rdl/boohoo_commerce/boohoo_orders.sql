------------------------------------------------------------------------------------------------------------------------
-- rdl_boohoo_commerce.boohoo_orders
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
        order_id,
        customer_id,
        order_date AS order_timestamp,
        order_total AS total_amount,
        order_status AS status,
        payment_method,
        discount_amount,
        shipping_cost,
        item_count,
        promo_code,
        delivery_method,
        warehouse_id AS fulfilment_centre,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_boohoo_commerce', 'boohoo_orders_history') }}
),
dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS rnk
    FROM history
)
SELECT
    order_id,
    customer_id,
    order_timestamp::TIMESTAMP AS order_timestamp,
    total_amount,
    status,
    payment_method,
    discount_amount,
    shipping_cost,
    item_count,
    promo_code,
    delivery_method,
    fulfilment_centre,
    'Boohoo' AS brand,
    'boohoo_commerce' AS source_system,
    ingest_date,
    ingest_ts
FROM dedup WHERE rnk = 1
