--@variable "rdl_ga" ${SCHEMA_RDL_GA}

------------------------------------------------------------------------------------------------------------------------
-- ga4_sessions
-- Deduplicated GA4 web sessions from ga4_sessions_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_ga".ga4_sessions;

CREATE TABLE "rdl_ga".ga4_sessions
DISTSTYLE KEY DISTKEY (session_id)
SORTKEY (session_date)
AS
WITH history AS (
    SELECT session_id, user_pseudo_id, session_date, session_timestamp,
           data."source", data."medium", data."channel_group", data."utm_campaign",
           data."device_category", data."country", data."landing_page",
           data."page_views", data."session_duration_seconds",
           data."is_bounced", data."is_engaged_session", data."is_new_user",
           data."transactions", data."revenue", data."add_to_carts", data."checkouts",
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_ga".ga4_sessions_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY session_id, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    session_id                                      :: VARCHAR(100)     AS session_id,
    user_pseudo_id                                  :: VARCHAR(100)     AS user_pseudo_id,
    session_date                                    :: DATE             AS date_nk,
    session_timestamp                               :: TIMESTAMP        AS session_timestamp,
    source                                          :: VARCHAR(200)     AS source,
    medium                                          :: VARCHAR(100)     AS medium,
    channel_group                                   :: VARCHAR(100)     AS channel_group,
    utm_campaign                                    :: VARCHAR(500)     AS utm_campaign,
    device_category                                 :: VARCHAR(50)      AS device_category,
    country                                         :: VARCHAR(100)     AS country,
    landing_page                                    :: VARCHAR(2000)    AS landing_page,
    page_views                                      :: INT             AS page_views,
    session_duration_seconds                        :: INT             AS session_duration_seconds,
    is_bounced                                      :: BOOLEAN         AS is_bounced,
    is_engaged_session                              :: BOOLEAN         AS is_engaged_session,
    is_new_user                                     :: BOOLEAN         AS is_new_user,
    transactions                                    :: INT             AS transactions,
    revenue                                         :: DECIMAL(18,2)   AS revenue,
    add_to_carts                                    :: INT             AS add_to_carts,
    checkouts                                       :: INT             AS checkouts,
    brand                                           :: VARCHAR(50)     AS brand,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
