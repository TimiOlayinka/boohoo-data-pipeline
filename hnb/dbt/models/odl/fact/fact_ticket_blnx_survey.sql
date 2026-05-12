------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_ticket_blnx_survey
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_blnx_survey') }}
)
SELECT
    survey_id, MD5(ticket_id) AS ticket_sk, MD5(agent_id) AS agent_sk, customer_id, csat_score, resolution_score, effort_score, comments, survey_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
