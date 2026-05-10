--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- map_channel_grouping
-- Maps Google Ads channel_type + campaign_name → channel_group
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".map_channel_grouping;

CREATE TABLE "dev_odl".map_channel_grouping
DISTSTYLE ALL
SORTKEY (channel_type)
AS
SELECT 'SEARCH'          :: VARCHAR(50) AS channel_type, '%Branded%'   :: VARCHAR(100) AS campaign_pattern, 'Branded Search'  :: VARCHAR(50) AS channel_group
UNION ALL SELECT 'SEARCH',               '%Generic%',    'Generic Search'
UNION ALL SELECT 'SEARCH',               '%NonBranded%', 'Generic Search'
UNION ALL SELECT 'SEARCH',               '%Competitor%', 'Competitor Search'
UNION ALL SELECT 'SHOPPING',             '%Standard%',   'Shopping'
UNION ALL SELECT 'SHOPPING',             '%Smart%',      'Smart Shopping'
UNION ALL SELECT 'PERFORMANCE_MAX',      '%PMax%',       'Performance Max'
UNION ALL SELECT 'DEMAND_GEN',           '%DemandGen%',  'Demand Gen'
UNION ALL SELECT 'VIDEO',                '%Video%',      'Video / YouTube'
UNION ALL SELECT 'VIDEO',                '%YT%',         'Video / YouTube'
;

COMMIT TRANSACTION;
