------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_ticket_interactions
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_ticket_interactions') }}
)
SELECT
    interaction_id, MD5(ticket_id) AS ticket_sk, MD5(agent_id) AS agent_sk, customer_id, channel, message_length, sentiment_score, interaction_timestamp,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
