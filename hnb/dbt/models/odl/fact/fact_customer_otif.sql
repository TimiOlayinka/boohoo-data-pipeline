------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_customer_otif
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_customer_otif') }}
)
SELECT
    otif_id, order_id, customer_id, promised_date, actual_delivery_date, is_on_time, is_in_full, defect_reason,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
