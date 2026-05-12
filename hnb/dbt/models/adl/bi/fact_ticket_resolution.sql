------------------------------------------------------------------------------------------------------------------------
-- bi.fact_ticket_resolution
------------------------------------------------------------------------------------------------------------------------
SELECT
    t.created_at::DATE AS date,
    t.priority,
    t.status,
    a.team_nk AS team_id,
    COUNT(t.ticket_nk) AS total_tickets,
    ROUND(AVG(s.csat_score), 2) AS avg_csat,
    ROUND(AVG(s.resolution_score), 2) AS avg_resolution
FROM {{ ref('dim_tickets') }} t
LEFT JOIN {{ ref('fact_ticket_blnx_survey') }} s ON t.ticket_sk = s.ticket_sk
LEFT JOIN {{ ref('dim_agents') }} a ON t.agent_id = a.agent_nk
GROUP BY 1, 2, 3, 4
