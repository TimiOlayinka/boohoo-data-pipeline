------------------------------------------------------------------------------------------------------------------------
-- rdl_zendesk.tickets
-- Deduplicated from tickets_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT ticket_id, customer_id, order_id, status, priority, subject, created_at, updated_at, agent_id, team_id,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_zendesk', 'tickets_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY ticket_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT ticket_id, customer_id, order_id, status, priority, subject, created_at, updated_at, agent_id, team_id, 'zendesk' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
