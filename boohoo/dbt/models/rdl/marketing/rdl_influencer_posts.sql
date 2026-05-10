------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.influencer_posts
-- Deduplicated influencer post performance from influencer_posts_history
-- Pattern: history → dedup (ROW_NUMBER) → SELECT WHERE rnk = 1
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT post_id, creator_handle, creator_name, creator_tier, creator_followers,
           platform, content_type, post_date, post_url,
           category_promoted, promo_code, tracking_url,
           cost, reach, impressions, likes, comments, shares, saves,
           total_engagement, engagement_rate, link_clicks,
           conversions, revenue_attributed, emv,
           brand,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'influencer_posts_history') }}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY post_id, brand
        ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT post_id, creator_handle, creator_name, creator_tier,
       creator_followers, platform, content_type,
       post_date::DATE AS date_nk, post_url,
       category_promoted, promo_code, tracking_url,
       cost::NUMERIC(18,2) AS cost,
       reach, impressions, likes, comments, shares, saves,
       total_engagement,
       engagement_rate::NUMERIC(8,4) AS engagement_rate,
       link_clicks, conversions,
       revenue_attributed::NUMERIC(18,2) AS revenue_attributed,
       emv::NUMERIC(18,2) AS emv,
       brand, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
