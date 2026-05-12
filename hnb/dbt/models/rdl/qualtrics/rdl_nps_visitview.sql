------------------------------------------------------------------------------------------------------------------------
-- rdl_qualtrics.nps_visitview
-- Deduplicated from nps_visitview_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT response_id, customer_id, order_id, nps_score, nps_category, feedback_text, device_type, response_date,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_qualtrics', 'nps_visitview_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY response_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT response_id, customer_id, order_id, nps_score, nps_category, feedback_text, device_type, response_date, 'qualtrics' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
