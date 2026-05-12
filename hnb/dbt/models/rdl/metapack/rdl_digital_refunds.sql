------------------------------------------------------------------------------------------------------------------------
-- rdl_metapack.digital_refunds
-- Deduplicated from digital_refunds_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT refund_id, order_id, customer_id, refund_amount, refund_reason, status, processed_date,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_metapack', 'digital_refunds_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY refund_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT refund_id, order_id, customer_id, refund_amount, refund_reason, status, processed_date, 'metapack' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
