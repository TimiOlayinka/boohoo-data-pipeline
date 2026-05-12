------------------------------------------------------------------------------------------------------------------------
-- rdl_metapack.parcel_events
-- Deduplicated from parcel_events_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT event_id, parcel_id, delivery_id, carrier, event_type, location, event_timestamp,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_metapack', 'parcel_events_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY event_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT event_id, parcel_id, delivery_id, carrier, event_type, location, event_timestamp, 'metapack' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
