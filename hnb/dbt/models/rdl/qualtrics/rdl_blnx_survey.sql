------------------------------------------------------------------------------------------------------------------------
-- rdl_qualtrics.blnx_survey
-- Deduplicated from blnx_survey_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT survey_id, ticket_id, customer_id, agent_id, csat_score, resolution_score, effort_score, comments, survey_date,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_qualtrics', 'blnx_survey_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY survey_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT survey_id, ticket_id, customer_id, agent_id, csat_score, resolution_score, effort_score, comments, survey_date, 'qualtrics' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
