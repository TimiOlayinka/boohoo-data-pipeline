------------------------------------------------------------------------------------------------------------------------
-- bi.fact_cx_nps_summary
------------------------------------------------------------------------------------------------------------------------
SELECT
    response_date AS date,
    device_type,
    nps_category,
    COUNT(response_id) AS total_responses,
    ROUND(AVG(nps_score), 2) AS avg_nps_score
FROM {{ ref('fact_nps_visitview') }}
GROUP BY 1, 2, 3
