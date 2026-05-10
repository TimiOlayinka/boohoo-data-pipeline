--@variable "rdl_google_ads" ${SCHEMA_RDL_GOOGLE_ADS}

------------------------------------------------------------------------------------------------------------------------
-- standard_campaigns
-- Deduplicated Google Ads performance from standard_campaigns_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_google_ads".standard_campaigns;

CREATE TABLE "rdl_google_ads".standard_campaigns
DISTSTYLE KEY DISTKEY (ad_id)
SORTKEY (date_day)
AS
WITH history AS (
    SELECT customer_id, data."customer_name",
           campaign_id, data."campaign_name", data."campaign_status",
           data."channel_type", data."ad_group_id", ad_id,
           date_day, data."device", data."ad_network_type",
           data."cost_micros", data."spend",
           data."impressions", data."clicks", data."interactions",
           data."conversions", data."conversions_value",
           data."all_conversions", data."all_conversions_value",
           data."video_quartile_p25_rate", data."video_quartile_p50_rate",
           data."video_quartile_p75_rate", data."video_quartile_p100_rate",
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_google_ads".standard_campaigns_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY ad_id, date_day, device, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    customer_id                                     :: VARCHAR(50)      AS customer_id,
    customer_name                                   :: VARCHAR(200)     AS customer_name,
    campaign_id                                     :: VARCHAR(50)      AS campaign_id,
    campaign_name                                   :: VARCHAR(5000)    AS campaign_name,
    campaign_status                                 :: VARCHAR(20)      AS campaign_status,
    channel_type                                    :: VARCHAR(50)      AS channel_type,
    ad_group_id                                     :: VARCHAR(50)      AS ad_group_id,
    ad_id                                           :: VARCHAR(50)      AS ad_id,
    date_day                                        :: DATE             AS date_nk,
    device                                          :: VARCHAR(20)      AS device,
    ad_network_type                                 :: VARCHAR(50)      AS ad_network_type,
    cost_micros                                     :: BIGINT           AS cost_micros,
    spend                                           :: DECIMAL(18,2)    AS spend,
    impressions                                     :: BIGINT           AS impressions,
    clicks                                          :: BIGINT           AS clicks,
    interactions                                    :: BIGINT           AS interactions,
    conversions                                     :: DECIMAL(18,2)    AS conversions,
    conversions_value                               :: DECIMAL(18,2)    AS conversions_value,
    all_conversions                                 :: DECIMAL(18,2)    AS all_conversions,
    all_conversions_value                           :: DECIMAL(18,2)    AS all_conversions_value,
    video_quartile_p25_rate                         :: DECIMAL(18,2)    AS video_quartile_p25_rate,
    video_quartile_p50_rate                         :: DECIMAL(18,2)    AS video_quartile_p50_rate,
    video_quartile_p75_rate                         :: DECIMAL(18,2)    AS video_quartile_p75_rate,
    video_quartile_p100_rate                        :: DECIMAL(18,2)    AS video_quartile_p100_rate,
    brand                                           :: VARCHAR(50)      AS brand,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
