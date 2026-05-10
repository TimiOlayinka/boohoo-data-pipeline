--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- map_utm_sources
-- Maps utm_source/medium combinations to traffic source hierarchy
-- Pattern: L1 (channel type) → L2 (platform)
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".map_utm_sources;

CREATE TABLE "dev_odl".map_utm_sources
DISTSTYLE ALL
SORTKEY (utm_source)
AS
SELECT 'google'     :: VARCHAR(50) AS utm_source, 'cpc'       :: VARCHAR(50) AS utm_medium, 'Paid Search'    :: VARCHAR(50) AS traffic_source_l1, 'Google Ads'     :: VARCHAR(50) AS traffic_source_l2
UNION ALL SELECT 'google',        'organic',    'Organic Search',  'Google Organic'
UNION ALL SELECT 'google',        'shopping',   'Paid Shopping',   'Google Shopping'
UNION ALL SELECT 'bing',          'cpc',        'Paid Search',     'Microsoft Ads'
UNION ALL SELECT 'facebook',      'cpc',        'Paid Social',     'Meta Ads'
UNION ALL SELECT 'instagram',     'cpc',        'Paid Social',     'Meta Ads'
UNION ALL SELECT 'tiktok',        'cpc',        'Paid Social',     'TikTok Ads'
UNION ALL SELECT 'email',         'email',      'Email',           'Email / CRM'
UNION ALL SELECT '(direct)',      '(none)',     'Direct',          'Direct'
UNION ALL SELECT 'affiliate',     'referral',   'Affiliates',      'Affiliate Partners'
UNION ALL SELECT 'pinterest',     'referral',   'Organic Social',  'Pinterest'
UNION ALL SELECT 'youtube',       'video',      'Video',           'YouTube'
UNION ALL SELECT 'influencer',    'referral',   'Influencer',      'Influencer'
;

COMMIT TRANSACTION;
