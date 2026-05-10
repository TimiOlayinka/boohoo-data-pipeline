--@variable "rdl_manual" ${SCHEMA_RDL_MANUAL}

------------------------------------------------------------------------------------------------------------------------
-- email_campaigns
-- Deduplicated email campaign performance from email_campaigns_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_manual".email_campaigns;

CREATE TABLE "rdl_manual".email_campaigns
DISTSTYLE KEY DISTKEY (campaign_id)
SORTKEY (send_date)
AS
WITH history AS (
    SELECT campaign_id, data."campaign_name", data."campaign_type", data."subject_line",
           send_date, data."send_timestamp", data."list_size",
           data."delivered", data."opened", data."unique_opens",
           data."clicked", data."unique_clicks",
           data."unsubscribed", data."bounced", data."spam_complaints",
           data."converted", data."revenue",
           data."open_rate", data."click_rate",
           data."click_to_open_rate", data."conversion_rate", data."revenue_per_email",
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_manual".email_campaigns_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY campaign_id, send_date, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    campaign_id                                     :: VARCHAR(50)      AS campaign_id,
    campaign_name                                   :: VARCHAR(500)     AS campaign_name,
    campaign_type                                   :: VARCHAR(50)      AS campaign_type,
    subject_line                                    :: VARCHAR(1000)    AS subject_line,
    send_date                                       :: DATE             AS date_nk,
    send_timestamp                                  :: TIMESTAMP        AS send_timestamp,
    list_size                                       :: INT             AS list_size,
    delivered                                       :: INT             AS delivered,
    opened                                          :: INT             AS opened,
    unique_opens                                    :: INT             AS unique_opens,
    clicked                                         :: INT             AS clicked,
    unique_clicks                                   :: INT             AS unique_clicks,
    unsubscribed                                    :: INT             AS unsubscribed,
    bounced                                         :: INT             AS bounced,
    spam_complaints                                 :: INT             AS spam_complaints,
    converted                                       :: INT             AS converted,
    revenue                                         :: DECIMAL(18,2)   AS revenue,
    open_rate                                       :: DECIMAL(8,2)    AS open_rate,
    click_rate                                      :: DECIMAL(8,2)    AS click_rate,
    click_to_open_rate                              :: DECIMAL(8,2)    AS click_to_open_rate,
    conversion_rate                                 :: DECIMAL(8,2)    AS conversion_rate,
    revenue_per_email                               :: DECIMAL(10,4)   AS revenue_per_email,
    brand                                           :: VARCHAR(50)     AS brand,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
