------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_basket_items
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_basket_items') }}
)
SELECT
    basket_item_id, basket_id, item_sku, quantity, unit_price, added_timestamp,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
