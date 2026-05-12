------------------------------------------------------------------------------------------------------------------------
-- rdl_zendesk.teams
-- Deduplicated from teams_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT team_id, team_name, tier, specialty,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_zendesk', 'teams_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY team_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT team_id, team_name, tier, specialty, 'zendesk' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
