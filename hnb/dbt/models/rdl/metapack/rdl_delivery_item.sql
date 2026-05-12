------------------------------------------------------------------------------------------------------------------------
-- rdl_metapack.delivery_item
-- Deduplicated from delivery_item_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT delivery_item_id, delivery_id, item_sku, quantity, status,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_metapack', 'delivery_item_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY delivery_item_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT delivery_item_id, delivery_id, item_sku, quantity, status, 'metapack' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
