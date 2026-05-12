------------------------------------------------------------------------------------------------------------------------
-- odl.dim.dim_teams
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_teams') }}
)
SELECT
    MD5(team_id) AS team_sk,
    team_id AS team_nk, team_name, tier, specialty,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
