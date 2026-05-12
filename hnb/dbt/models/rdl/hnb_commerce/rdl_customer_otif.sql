------------------------------------------------------------------------------------------------------------------------
-- rdl_hnb_commerce.customer_otif
-- Deduplicated from customer_otif_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT otif_id, order_id, customer_id, promised_date, actual_delivery_date, is_on_time, is_in_full, defect_reason,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_hnb_commerce', 'customer_otif_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY otif_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT otif_id, order_id, customer_id, promised_date, actual_delivery_date, is_on_time, is_in_full, defect_reason, 'hnb_commerce' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
