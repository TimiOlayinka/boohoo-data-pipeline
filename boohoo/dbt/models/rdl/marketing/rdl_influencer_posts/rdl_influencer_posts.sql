------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.influencer_posts
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
post_id,
        creator_handle,
        creator_name,
        creator_tier,
        creator_followers,
        platform,
        content_type,
        post_date,
        post_url,
        category_promoted,
        promo_code,
        tracking_url,
        cost,
        reach,
        impressions,
        likes,
        comments,
        shares,
        saves,
        total_engagement,
        engagement_rate,
        link_clicks,
        conversions,
        revenue_attributed,
        emv,
        brand,
        ingest_date,
        REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{ source('rdl_marketing', 'influencer_posts_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY post_id, brand
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY post_id, brand
        ) AS version_count,
        MD5(
            COALESCE(post_id::VARCHAR, '') || '|' ||
            COALESCE(creator_handle::VARCHAR, '') || '|' ||
            COALESCE(creator_name::VARCHAR, '') || '|' ||
            COALESCE(creator_tier::VARCHAR, '') || '|' ||
            COALESCE(creator_followers::VARCHAR, '') || '|' ||
            COALESCE(platform::VARCHAR, '') || '|' ||
            COALESCE(content_type::VARCHAR, '') || '|' ||
            COALESCE(post_date::VARCHAR, '') || '|' ||
            COALESCE(post_url::VARCHAR, '') || '|' ||
            COALESCE(category_promoted::VARCHAR, '') || '|' ||
            COALESCE(promo_code::VARCHAR, '') || '|' ||
            COALESCE(tracking_url::VARCHAR, '') || '|' ||
            COALESCE(cost::VARCHAR, '') || '|' ||
            COALESCE(reach::VARCHAR, '') || '|' ||
            COALESCE(impressions::VARCHAR, '') || '|' ||
            COALESCE(likes::VARCHAR, '') || '|' ||
            COALESCE(comments::VARCHAR, '') || '|' ||
            COALESCE(shares::VARCHAR, '') || '|' ||
            COALESCE(saves::VARCHAR, '') || '|' ||
            COALESCE(total_engagement::VARCHAR, '') || '|' ||
            COALESCE(engagement_rate::VARCHAR, '') || '|' ||
            COALESCE(link_clicks::VARCHAR, '') || '|' ||
            COALESCE(conversions::VARCHAR, '') || '|' ||
            COALESCE(revenue_attributed::VARCHAR, '') || '|' ||
            COALESCE(emv::VARCHAR, '') || '|' ||
            COALESCE(brand::VARCHAR, '')
        ) AS record_hash
    FROM history
)
SELECT
    post_id,
    creator_handle,
    creator_name,
    creator_tier,
    creator_followers,
    platform,
    content_type,
    post_date::DATE AS date_nk,
    post_url,
    category_promoted,
    promo_code,
    tracking_url,
    cost::NUMERIC(18,2) AS cost,
    reach,
    impressions,
    likes,
    comments,
    shares,
    saves,
    total_engagement,
    engagement_rate::NUMERIC(8,4) AS engagement_rate,
    link_clicks,
    conversions,
    revenue_attributed::NUMERIC(18,2) AS revenue_attributed,
    emv::NUMERIC(18,2) AS emv,
    brand,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
