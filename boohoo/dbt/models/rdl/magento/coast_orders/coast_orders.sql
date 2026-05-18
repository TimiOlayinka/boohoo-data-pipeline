------------------------------------------------------------------------------------------------------------------------
-- rdl_magento.coast_orders
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
increment_id AS order_id,
        customer_id,
        created_at AS order_timestamp,
        grand_total AS total_amount,
        status,
        payment_method,
        discount_amount,
        shipping_cost,
        item_count,
        coupon_code AS promo_code,
        shipping_method AS delivery_method,
        store_id AS fulfilment_centre,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_magento', 'coast_orders_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS version_count,
        MD5(
            COALESCE(order_id::VARCHAR, '') || '|' ||
            COALESCE(customer_id::VARCHAR, '') || '|' ||
            COALESCE(order_timestamp::VARCHAR, '') || '|' ||
            COALESCE(total_amount::VARCHAR, '') || '|' ||
            COALESCE(status::VARCHAR, '') || '|' ||
            COALESCE(payment_method::VARCHAR, '') || '|' ||
            COALESCE(discount_amount::VARCHAR, '') || '|' ||
            COALESCE(shipping_cost::VARCHAR, '') || '|' ||
            COALESCE(item_count::VARCHAR, '') || '|' ||
            COALESCE(promo_code::VARCHAR, '') || '|' ||
            COALESCE(delivery_method::VARCHAR, '') || '|' ||
            COALESCE(fulfilment_centre::VARCHAR, '')
        ) AS record_hash
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
    ingest_date,
    ingest_ts,
    'Coast' AS brand,
    'magento' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
