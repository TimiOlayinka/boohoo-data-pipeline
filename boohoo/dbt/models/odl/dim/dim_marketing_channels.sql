------------------------------------------------------------------------------------------------------------------------
-- odl.dim_marketing_channels
-- Marketing channel hierarchy dimension — L1 (Channel Type) → L2 (Platform) → L3 (Sub-channel)
-- Follows HnB dim_traffic_sources pattern
------------------------------------------------------------------------------------------------------------------------
SELECT 'Paid Social'       AS channel_l1, 'Meta Ads'          AS channel_l2, 'Facebook'         AS channel_l3, 'meta_ads'       AS source_system
UNION ALL SELECT 'Paid Social',          'Meta Ads',           'Instagram',        'meta_ads'
UNION ALL SELECT 'Paid Social',          'Meta Ads',           'Audience Network', 'meta_ads'
UNION ALL SELECT 'Paid Social',          'TikTok Ads',         'TikTok',           'tiktok_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Search',           'google_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Shopping',         'google_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Performance Max',  'google_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Demand Gen',       'google_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Video',            'google_ads'
UNION ALL SELECT 'Paid Search',          'Google Ads',         'Display',          'google_ads'
UNION ALL SELECT 'Email',                'Email / CRM',       'Promotional',      'email'
UNION ALL SELECT 'Email',                'Email / CRM',       'Automated',        'email'
UNION ALL SELECT 'Email',                'Email / CRM',       'Transactional',    'email'
UNION ALL SELECT 'Influencer',           'Influencer',         'Instagram',        'influencer'
UNION ALL SELECT 'Influencer',           'Influencer',         'TikTok',           'influencer'
UNION ALL SELECT 'Influencer',           'Influencer',         'YouTube',          'influencer'
UNION ALL SELECT 'Organic Search',       'Google Organic',     'SEO',              'ga4'
UNION ALL SELECT 'Direct',               'Direct',             'Direct',           'ga4'
UNION ALL SELECT 'Referral',             'Affiliates',         'Affiliate',        'ga4'
UNION ALL SELECT 'Organic Social',       'Social Organic',     'Pinterest',        'ga4'
