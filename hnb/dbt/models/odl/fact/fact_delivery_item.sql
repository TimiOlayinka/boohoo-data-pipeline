------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_delivery_item
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_delivery_item') }}
)
SELECT
    delivery_item_id, delivery_id, item_sku, quantity, status,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
