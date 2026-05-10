--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_email_engagement
-- Email campaign engagement fact table with delivery and conversion metrics
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_email_engagement;

CREATE TABLE "dev_odl".fact_email_engagement
DISTSTYLE KEY DISTKEY (campaign_nk)
SORTKEY (date_nk)
AS
SELECT
    MD5(e.campaign_id || '|' || e.date_nk || '|' || e.brand)
                                                        :: VARCHAR(32)      AS email_engagement_sk,
    e.campaign_id                                       :: VARCHAR(50)      AS campaign_nk,
    e.campaign_name                                     :: VARCHAR(500)     AS campaign_name,
    e.campaign_type                                     :: VARCHAR(50)      AS campaign_type,
    e.subject_line                                      :: VARCHAR(1000)    AS subject_line,
    e.date_nk,
    EXTRACT(YEAR FROM e.date_nk)                        :: INT              AS year,
    EXTRACT(MONTH FROM e.date_nk)                       :: INT              AS month,
    e.send_timestamp,
    e.list_size,
    e.delivered,
    e.opened,
    e.unique_opens,
    e.clicked,
    e.unique_clicks,
    e.unsubscribed,
    e.bounced,
    e.spam_complaints,
    e.converted,
    e.revenue,
    -- Calculated rates
    ROUND(e.delivered::FLOAT / NULLIF(e.list_size, 0) * 100, 2)
                                                        :: DECIMAL(8,2)     AS delivery_rate,
    e.open_rate,
    e.click_rate,
    e.click_to_open_rate,
    e.conversion_rate,
    e.revenue_per_email,
    e.brand,
    mb.brand_tier,
    e.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM "rdl_manual".email_campaigns e
LEFT JOIN "dev_odl".map_brand mb
    ON e.brand = mb.brand
;

COMMIT TRANSACTION;
