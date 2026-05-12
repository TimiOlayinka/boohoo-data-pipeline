------------------------------------------------------------------------------------------------------------------------
-- rdl_zendesk.agents
-- Deduplicated from agents_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT agent_id, name, email, team_id, status, created_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_zendesk', 'agents_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY agent_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT agent_id, name, email, team_id, status, created_at, 'zendesk' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
