------------------------------------------------------------------------------------------------------------------------
-- rdl_metapack.delivery_order
-- Deduplicated from delivery_order_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT delivery_id, order_id, customer_id, shipping_address, carrier, service_level, estimated_delivery_date,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_metapack', 'delivery_order_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY delivery_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT delivery_id, order_id, customer_id, shipping_address, carrier, service_level, estimated_delivery_date, 'metapack' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
