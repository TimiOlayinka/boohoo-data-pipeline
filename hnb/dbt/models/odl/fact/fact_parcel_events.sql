------------------------------------------------------------------------------------------------------------------------
-- odl.fact.fact_parcel_events
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_parcel_events') }}
)
SELECT
    event_id, parcel_id, delivery_id, carrier, event_type, location, event_timestamp,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
