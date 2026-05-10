--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- map_brand
-- Brand reference mapping — Boohoo Group brands with tier classification
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".map_brand;

CREATE TABLE "dev_odl".map_brand
DISTSTYLE ALL
SORTKEY (brand)
AS
SELECT 'Boohoo'             :: VARCHAR(50) AS brand, 'boohoo_commerce'       :: VARCHAR(50) AS source_system, 'Value'   :: VARCHAR(10) AS brand_tier, 'boohoo.com'              :: VARCHAR(100) AS website
UNION ALL SELECT 'Boohoo Man',         'boohoo_commerce',       'Value',   'boohooman.com'
UNION ALL SELECT 'PrettyLittleThing',  'salesforce_commerce',   'Value',   'prettylittlething.com'
UNION ALL SELECT 'NastyGal',           'shopify',               'Mid',     'nastygal.com'
UNION ALL SELECT 'Karen Millen',       'magento',               'Premium', 'karenmillen.com'
UNION ALL SELECT 'Coast',              'magento',               'Premium', 'coast-stores.com'
UNION ALL SELECT 'Debenhams',          'oracle_commerce',       'Mid',     'debenhams.com'
;

COMMIT TRANSACTION;
