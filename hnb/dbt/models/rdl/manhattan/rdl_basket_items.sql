------------------------------------------------------------------------------------------------------------------------
-- rdl_manhattan.basket_items
-- Deduplicated from basket_items_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT basket_item_id, basket_id, item_sku, quantity, unit_price, added_timestamp,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_manhattan', 'basket_items_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY basket_item_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT basket_item_id, basket_id, item_sku, quantity, unit_price, added_timestamp, 'manhattan' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
