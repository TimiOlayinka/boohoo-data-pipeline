------------------------------------------------------------------------------------------------------------------------
-- odl.dim_time
-- Conformed date dimension
------------------------------------------------------------------------------------------------------------------------
WITH date_spine AS (
    SELECT (DATE '2024-01-01' + ROW_NUMBER() OVER () - 1)::DATE AS date_day
    FROM stv_blocklist  -- Redshift system table to generate rows
    LIMIT 1096  -- ~3 years
)
SELECT
    date_day                                    AS date_day,
    EXTRACT(DOW FROM date_day)                 AS day_of_week,
    TO_CHAR(date_day, 'Day')                   AS day_name,
    EXTRACT(DAY FROM date_day)                 AS day_of_month,
    EXTRACT(MONTH FROM date_day)               AS month_number,
    TO_CHAR(date_day, 'Month')                 AS month_name,
    EXTRACT(QUARTER FROM date_day)             AS quarter,
    EXTRACT(YEAR FROM date_day)                AS year,
    TO_CHAR(date_day, 'IYYY-IW')              AS iso_week,
    CASE WHEN EXTRACT(DOW FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
    CASE WHEN EXTRACT(MONTH FROM date_day) IN (11,12,1) THEN TRUE ELSE FALSE END AS is_peak_season
FROM date_spine
