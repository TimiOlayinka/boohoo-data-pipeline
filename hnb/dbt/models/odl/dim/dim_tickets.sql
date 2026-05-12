------------------------------------------------------------------------------------------------------------------------
-- odl.dim.dim_tickets
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{ ref('rdl_tickets') }}
)
SELECT
    MD5(ticket_id) AS ticket_sk,
    ticket_id AS ticket_nk, customer_id, order_id, status, priority, subject, created_at, updated_at,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
