--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_tiktok_ad_insights
-- TikTok Ads performance with surrogate keys and brand tier mapping
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_tiktok_ad_insights;

CREATE TABLE "dev_odl".fact_tiktok_ad_insights
DISTSTYLE KEY DISTKEY (tiktok_ad_nk)
SORTKEY (date_nk)
AS
WITH raw_data AS (
    SELECT
        ad_id                                           :: VARCHAR(50)      AS tiktok_ad_nk,
        advertiser_id                                   :: VARCHAR(50)      AS tiktok_advertiser_id,
        campaign_name                                   :: VARCHAR(5000)    AS tiktok_campaign_name,
        objective                                       :: VARCHAR(50)      AS objective,
        date_nk                                         :: DATE             AS date_nk,
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
        ingest_date
    FROM "rdl_tiktok_ads".tiktok_ads
)
SELECT
    MD5(rd.tiktok_ad_nk || '|' || rd.date_nk || '|' || rd.brand)
                                                        :: VARCHAR(32)      AS tiktok_ad_sk,
    rd.tiktok_ad_nk,
    rd.tiktok_advertiser_id,
    rd.tiktok_campaign_name,
    rd.objective,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       :: INT              AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      :: INT              AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.ctr,
    rd.cpc,
    rd.cpm,
    rd.conversion_rate,
    rd.conversion,
    rd.cost_per_conversion,
    rd.purchase,
    rd.video_play_actions,
    rd.video_watched_2s,
    rd.video_watched_6s,
    rd.video_views_p25,
    rd.video_views_p50,
    rd.video_views_p75,
    rd.video_views_p100,
    rd.brand,
    mb.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM raw_data rd
LEFT JOIN "dev_odl".map_brand mb
    ON rd.brand = mb.brand
;

COMMIT TRANSACTION;
