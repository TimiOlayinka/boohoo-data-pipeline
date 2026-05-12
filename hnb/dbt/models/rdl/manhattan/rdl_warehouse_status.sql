------------------------------------------------------------------------------------------------------------------------
-- rdl_manhattan.warehouse_status
-- Deduplicated from warehouse_status_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT status_id, basket_id, warehouse_location, status, picker_id, timestamp,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_manhattan', 'warehouse_status_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY status_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT status_id, basket_id, warehouse_location, status, picker_id, timestamp, 'manhattan' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
