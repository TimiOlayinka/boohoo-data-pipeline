------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_digital_refunds
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_digital_refunds') }}
)
SELECT
    refund_id, order_id, customer_id, refund_amount, refund_reason, status, processed_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
