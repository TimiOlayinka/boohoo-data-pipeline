------------------------------------------------------------------------------------------------------------------------
-- rdl_zendesk.ticket_interactions
-- Deduplicated from ticket_interactions_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT interaction_id, ticket_id, agent_id, customer_id, channel, message_length, sentiment_score, interaction_timestamp,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_zendesk', 'ticket_interactions_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY interaction_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT interaction_id, ticket_id, agent_id, customer_id, channel, message_length, sentiment_score, interaction_timestamp, 'zendesk' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
