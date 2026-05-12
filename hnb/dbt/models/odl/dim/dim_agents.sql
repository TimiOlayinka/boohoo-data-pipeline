------------------------------------------------------------------------------------------------------------------------
-- odl.dim.dim_agents
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_agents') }}
)
SELECT
    MD5(agent_id) AS agent_sk,
    agent_id AS agent_nk, name, email, team_id, status, created_at,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
