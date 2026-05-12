------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_basket_warehouse_status
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_warehouse_status') }}
)
SELECT
    status_id, basket_id, warehouse_location, status, picker_id, timestamp,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
