------------------------------------------------------------------------------------------------------------------------
-- odl.map_brand
-- Brand reference mapping
------------------------------------------------------------------------------------------------------------------------
SELECT 'Boohoo'             AS brand, 'boohoo_commerce'       AS source_system, 'Value'   AS brand_tier, 'boohoo.com'              AS website
UNION ALL SELECT 'Boohoo Man',         'boohoo_commerce',       'Value',   'boohooman.com'
UNION ALL SELECT 'PrettyLittleThing',  'salesforce_commerce',   'Value',   'prettylittlething.com'
UNION ALL SELECT 'NastyGal',           'shopify',               'Mid',     'nastygal.com'
UNION ALL SELECT 'Karen Millen',       'magento',               'Premium', 'karenmillen.com'
UNION ALL SELECT 'Coast',              'magento',               'Premium', 'coast-stores.com'
UNION ALL SELECT 'Debenhams',          'oracle_commerce',       'Mid',     'debenhams.com'
