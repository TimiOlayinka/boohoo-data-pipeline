------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_customer_otif_cc
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_customer_otif_cc') }}
)
SELECT
    otif_cc_id, order_id, contact_center_agent_id, override_reason, override_timestamp,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
