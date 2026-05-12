------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_delivery_order
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_delivery_order') }}
)
SELECT
    delivery_id, order_id, customer_id, shipping_address, carrier, service_level, estimated_delivery_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
