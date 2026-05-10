--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_meta_campaign_insights
-- Meta Ads campaign insights with surrogate keys and dimension lookups
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_meta_campaign_insights;

CREATE TABLE "dev_odl".fact_meta_campaign_insights
DISTSTYLE KEY DISTKEY (meta_campaign_nk)
SORTKEY (date_nk)
AS
WITH raw_data AS (
    SELECT
        campaign_id                                     :: VARCHAR(50)      AS meta_campaign_nk,
        campaign_name                                   :: VARCHAR(5000)    AS meta_campaign_name,
        objective                                       :: VARCHAR(50)      AS objective,
        account_id                                      :: VARCHAR(50)      AS meta_account_nk,
        publisher_platform                              :: VARCHAR(50)      AS publisher_platform,
        date_nk                                         :: DATE             AS date_nk,
        spend                                           :: DECIMAL(18,4)    AS spend,
        impressions                                     :: BIGINT           AS impressions,
        clicks                                          :: BIGINT           AS clicks,
        reach                                           :: BIGINT           AS reach,
        frequency                                       :: DECIMAL(18,4)    AS frequency,
        cpc                                             :: DECIMAL(18,4)    AS cpc,
        cpm                                             :: DECIMAL(18,4)    AS cpm,
        ctr                                             :: DECIMAL(18,4)    AS ctr,
        outbound_clicks                                 :: DECIMAL(18,4)    AS outbound_clicks,
        outbound_clicks_ctr                             :: DECIMAL(18,4)    AS outbound_clicks_ctr,
        video_p25_watched                               :: DECIMAL(18,4)    AS video_p25_watched,
        video_p50_watched                               :: DECIMAL(18,4)    AS video_p50_watched,
        video_p75_watched                               :: DECIMAL(18,4)    AS video_p75_watched,
        video_p100_watched                              :: DECIMAL(18,4)    AS video_p100_watched,
        brand                                           :: VARCHAR(50)      AS brand,
        ingest_date
    FROM "rdl_meta_ads".campaign_insights
)
SELECT
    MD5(rd.meta_campaign_nk || '|' || rd.date_nk || '|' || rd.publisher_platform || '|' || rd.brand)
                                                        :: VARCHAR(32)      AS meta_insight_sk,
    rd.meta_campaign_nk,
    rd.meta_campaign_name,
    dc.campaign_sk,
    dc.campaign_type,
    rd.objective,
    rd.publisher_platform,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       :: INT              AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      :: INT              AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.cpc,
    rd.cpm,
    rd.ctr,
    rd.outbound_clicks,
    rd.outbound_clicks_ctr,
    rd.video_p25_watched,
    rd.video_p50_watched,
    rd.video_p75_watched,
    rd.video_p100_watched,
    rd.brand,
    mb.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM raw_data rd
LEFT JOIN "dev_odl".dim_campaigns dc
    ON rd.meta_campaign_nk = dc.campaign_nk AND dc.platform = 'Meta Ads' AND rd.brand = dc.brand
LEFT JOIN "dev_odl".map_brand mb
    ON rd.brand = mb.brand
;

COMMIT TRANSACTION;
