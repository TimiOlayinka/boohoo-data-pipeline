------------------------------------------------------------------------------------------------------------------------
-- rdl_hnb_commerce.customer_otif_cc
-- Deduplicated from customer_otif_cc_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT otif_cc_id, order_id, contact_center_agent_id, override_reason, override_timestamp,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_hnb_commerce', 'customer_otif_cc_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY otif_cc_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT otif_cc_id, order_id, contact_center_agent_id, override_reason, override_timestamp, 'hnb_commerce' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
