------------------------------------------------------------------------------------------------------------------------
-- rdl_hnb_commerce.postship_defect
-- Deduplicated from postship_defect_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT defect_id, order_id, parcel_id, defect_type, severity, reported_date,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_hnb_commerce', 'postship_defect_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY defect_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT defect_id, order_id, parcel_id, defect_type, severity, reported_date, 'hnb_commerce' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
