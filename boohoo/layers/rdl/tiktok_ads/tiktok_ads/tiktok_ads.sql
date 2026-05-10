--@variable "rdl_tiktok_ads" ${SCHEMA_RDL_TIKTOK_ADS}

------------------------------------------------------------------------------------------------------------------------
-- tiktok_ads
-- Deduplicated TikTok Ads insights from tiktok_ads_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_tiktok_ads".tiktok_ads;

CREATE TABLE "rdl_tiktok_ads".tiktok_ads
DISTSTYLE KEY DISTKEY (ad_id)
SORTKEY (stat_time_day)
AS
WITH history AS (
    SELECT advertiser_id, ad_id,
           data."campaign_name", data."objective",
           stat_time_day,
           data."spend", data."impressions", data."clicks",
           data."reach", data."frequency",
           data."ctr", data."cpc", data."cpm",
           data."conversion_rate", data."conversion",
           data."cost_per_conversion", data."purchase",
           data."video_play_actions", data."video_watched_2s", data."video_watched_6s",
           data."video_views_p25", data."video_views_p50",
           data."video_views_p75", data."video_views_p100",
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_tiktok_ads".tiktok_ads_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY ad_id, stat_time_day, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    advertiser_id                                   :: VARCHAR(50)      AS advertiser_id,
    ad_id                                           :: VARCHAR(50)      AS ad_id,
    campaign_name                                   :: VARCHAR(5000)    AS campaign_name,
    objective                                       :: VARCHAR(50)      AS objective,
    stat_time_day                                   :: DATE             AS date_nk,
    spend                                           :: DECIMAL(18,4)    AS spend,
    impressions                                     :: BIGINT           AS impressions,
    clicks                                          :: BIGINT           AS clicks,
    reach                                           :: BIGINT           AS reach,
    frequency                                       :: DECIMAL(18,4)    AS frequency,
    ctr                                             :: DECIMAL(18,4)    AS ctr,
    cpc                                             :: DECIMAL(18,4)    AS cpc,
    cpm                                             :: DECIMAL(18,4)    AS cpm,
    conversion_rate                                 :: DECIMAL(18,4)    AS conversion_rate,
    conversion                                      :: BIGINT           AS conversion,
    cost_per_conversion                             :: DECIMAL(18,4)    AS cost_per_conversion,
    purchase                                        :: BIGINT           AS purchase,
    video_play_actions                              :: BIGINT           AS video_play_actions,
    video_watched_2s                                :: BIGINT           AS video_watched_2s,
    video_watched_6s                                :: BIGINT           AS video_watched_6s,
    video_views_p25                                 :: BIGINT           AS video_views_p25,
    video_views_p50                                 :: BIGINT           AS video_views_p50,
    video_views_p75                                 :: BIGINT           AS video_views_p75,
    video_views_p100                                :: BIGINT           AS video_views_p100,
    brand                                           :: VARCHAR(50)      AS brand,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
