--@variable "rdl_creatoriq" ${SCHEMA_RDL_CREATORIQ}

------------------------------------------------------------------------------------------------------------------------
-- influencer_posts
-- Deduplicated influencer post performance from influencer_posts_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_creatoriq".influencer_posts;

CREATE TABLE "rdl_creatoriq".influencer_posts
DISTSTYLE KEY DISTKEY (post_id)
SORTKEY (post_date)
AS
WITH history AS (
    SELECT post_id, data."creator_handle", data."creator_name",
           data."creator_tier", data."creator_followers",
           data."platform", data."content_type", post_date, data."post_url",
           data."category_promoted", data."promo_code", data."tracking_url",
           data."cost", data."reach", data."impressions",
           data."likes", data."comments", data."shares", data."saves",
           data."total_engagement", data."engagement_rate", data."link_clicks",
           data."conversions", data."revenue_attributed", data."emv",
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_creatoriq".influencer_posts_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY post_id, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    post_id                                         :: VARCHAR(50)      AS post_id,
    creator_handle                                  :: VARCHAR(200)     AS creator_handle,
    creator_name                                    :: VARCHAR(200)     AS creator_name,
    creator_tier                                    :: VARCHAR(20)      AS creator_tier,
    creator_followers                               :: BIGINT           AS creator_followers,
    platform                                        :: VARCHAR(50)      AS platform,
    content_type                                    :: VARCHAR(50)      AS content_type,
    post_date                                       :: DATE             AS date_nk,
    post_url                                        :: VARCHAR(2000)    AS post_url,
    category_promoted                               :: VARCHAR(100)     AS category_promoted,
    promo_code                                      :: VARCHAR(50)      AS promo_code,
    tracking_url                                    :: VARCHAR(2000)    AS tracking_url,
    cost                                            :: DECIMAL(18,2)    AS cost,
    reach                                           :: BIGINT           AS reach,
    impressions                                     :: BIGINT           AS impressions,
    likes                                           :: BIGINT           AS likes,
    comments                                        :: BIGINT           AS comments,
    shares                                          :: BIGINT           AS shares,
    saves                                           :: BIGINT           AS saves,
    total_engagement                                :: BIGINT           AS total_engagement,
    engagement_rate                                 :: DECIMAL(8,4)     AS engagement_rate,
    link_clicks                                     :: BIGINT           AS link_clicks,
    conversions                                     :: BIGINT           AS conversions,
    revenue_attributed                              :: DECIMAL(18,2)    AS revenue_attributed,
    emv                                             :: DECIMAL(18,2)    AS emv,
    brand                                           :: VARCHAR(50)      AS brand,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
