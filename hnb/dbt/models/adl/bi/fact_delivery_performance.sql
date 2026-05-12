------------------------------------------------------------------------------------------------------------------------
-- bi.fact_delivery_performance
------------------------------------------------------------------------------------------------------------------------
SELECT
    promised_date AS date,
    COUNT(otif_id) AS total_orders,
    SUM(CASE WHEN is_on_time = 'True' THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN is_in_full = 'True' THEN 1 ELSE 0 END) AS in_full_orders,
    defect_reason
FROM {{ ref('fact_customer_otif') }}
GROUP BY 1, 5
