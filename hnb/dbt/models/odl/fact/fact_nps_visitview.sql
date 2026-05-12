------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_nps_visitview
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_nps_visitview') }}
)
SELECT
    response_id, customer_id, order_id, nps_score, nps_category, feedback_text, device_type, response_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
