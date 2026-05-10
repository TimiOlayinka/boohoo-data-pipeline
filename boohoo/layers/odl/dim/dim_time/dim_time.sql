--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- dim_time
-- Conformed date dimension — date spine from 2024-01-01 to 2026-12-31
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".dim_time;

CREATE TABLE "dev_odl".dim_time
DISTSTYLE ALL
SORTKEY (date_day)
AS
WITH date_spine AS (
    SELECT (DATE '2024-01-01' + n)::DATE AS date_day
    FROM (SELECT ROW_NUMBER() OVER () - 1 AS n FROM pg_catalog.pg_class LIMIT 1096) seq
)
SELECT
    date_day                                        :: DATE           AS date_day,
    EXTRACT(DOW FROM date_day)                      :: INT            AS day_of_week,
    TO_CHAR(date_day, 'Day')                        :: VARCHAR(10)    AS day_name,
    EXTRACT(DAY FROM date_day)                      :: INT            AS day_of_month,
    EXTRACT(MONTH FROM date_day)                    :: INT            AS month_number,
    TO_CHAR(date_day, 'Month')                      :: VARCHAR(10)    AS month_name,
    EXTRACT(QUARTER FROM date_day)                  :: INT            AS quarter,
    EXTRACT(YEAR FROM date_day)                     :: INT            AS year,
    TO_CHAR(date_day, 'IYYY-IW')                    :: VARCHAR(8)     AS iso_week,
    CASE WHEN EXTRACT(DOW FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
    CASE WHEN EXTRACT(MONTH FROM date_day) IN (11,12,1) THEN TRUE ELSE FALSE END AS is_peak_season
FROM date_spine
;

COMMIT TRANSACTION;
