------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_postship_defect
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_postship_defect') }}
)
SELECT
    defect_id, order_id, parcel_id, defect_type, severity, reported_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
