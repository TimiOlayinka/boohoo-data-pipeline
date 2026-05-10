META_ADS_OBJECTIVES = ["OUTCOME_TRAFFIC", "OUTCOME_SALES", "OUTCOME_AWARENESS", "OUTCOME_ENGAGEMENT"]
META_ADS_PUBLISHER_PLATFORMS = ["facebook", "instagram", "audience_network"]
META_ADS_CAMPAIGN_TEMPLATES = [
    "{brand}_SS25_Dresses_Conversions", "{brand}_AW24_NewIn_Traffic",
    "{brand}_Retargeting_DPA_Conversions", "{brand}_Lookalike_Prospecting",
    "{brand}_Brand_Awareness_Reach", "{brand}_Sale_Event_Conversions",
    "{brand}_VIP_Engagement_Custom", "{brand}_Summer_Collection_Traffic",
    "{brand}_BlackFriday_DPA_Sales", "{brand}_Payday_Push_Conversions",
]

GOOGLE_ADS_CHANNEL_TYPES = ["SEARCH", "SHOPPING", "PERFORMANCE_MAX", "DEMAND_GEN", "VIDEO"]
GOOGLE_ADS_DEVICES = ["MOBILE", "DESKTOP", "TABLET"]
GOOGLE_ADS_NETWORK_TYPES = ["SEARCH", "SEARCH_PARTNERS", "CONTENT", "YOUTUBE_SEARCH", "YOUTUBE_WATCH"]
GOOGLE_ADS_CAMPAIGN_TEMPLATES = [
    "{brand}_Branded_Search_Core", "{brand}_Generic_Search_Dresses",
    "{brand}_Generic_Search_Tops", "{brand}_Shopping_Standard_All",
    "{brand}_PMax_All_Products", "{brand}_DemandGen_NewSeason",
    "{brand}_Video_YT_Brand", "{brand}_Branded_Search_Competitor",
    "{brand}_NonBranded_Search_Category", "{brand}_Shopping_Smart_Priority",
]

TIKTOK_ADS_OBJECTIVES = ["CONVERSIONS", "TRAFFIC", "REACH", "VIDEO_VIEWS", "APP_PROMOTION"]
TIKTOK_ADS_CAMPAIGN_TEMPLATES = [
    "{brand}_SparkAds_Conversions", "{brand}_TopView_Awareness",
    "{brand}_InFeed_Traffic", "{brand}_Collection_DPA",
    "{brand}_Branded_Hashtag_Challenge", "{brand}_UGC_Engagement",
    "{brand}_Sale_Retargeting", "{brand}_NewIn_Prospecting",
]

GA4_TRAFFIC_SOURCES = [
    ("google", "cpc", "Paid Search"),
    ("google", "organic", "Organic Search"),
    ("facebook", "cpc", "Paid Social"),
    ("instagram", "cpc", "Paid Social"),
    ("tiktok", "cpc", "Paid Social"),
    ("email", "email", "Email"),
    ("(direct)", "(none)", "Direct"),
    ("google", "shopping", "Paid Shopping"),
    ("bing", "cpc", "Paid Search"),
    ("affiliate", "referral", "Affiliates"),
    ("pinterest", "referral", "Social Organic"),
    ("youtube", "video", "Video"),
]
GA4_TRAFFIC_WEIGHTS = [20, 15, 15, 10, 8, 10, 12, 5, 2, 1, 1, 1]
GA4_DEVICES = ["mobile", "desktop", "tablet"]
GA4_DEVICE_WEIGHTS = [62, 30, 8]
GA4_LANDING_PAGES = [
    "/", "/new-in", "/dresses", "/tops", "/sale", "/shoes",
    "/collections/summer", "/collections/party", "/bestsellers",
    "/category/{cat}", "/product/{product_id}",
]

EMAIL_CAMPAIGN_TYPES = [
    "promotional", "abandoned_cart", "welcome_series",
    "win_back", "vip_exclusive", "new_arrivals",
    "sale_announcement", "birthday", "post_purchase",
]
EMAIL_CAMPAIGN_TEMPLATES = [
    "{brand}_Weekly_NewIn_{date}", "{brand}_AbandonedCart_24h",
    "{brand}_Welcome_Day1", "{brand}_Welcome_Day3", "{brand}_Welcome_Day7",
    "{brand}_WinBack_30Day", "{brand}_WinBack_60Day",
    "{brand}_VIP_EarlyAccess_{date}", "{brand}_Sale_Launch_{date}",
    "{brand}_PayDay_Promo_{date}", "{brand}_Birthday_Offer",
    "{brand}_PostPurchase_CrossSell", "{brand}_NewArrivals_{cat}_{date}",
    "{brand}_BlackFriday_Teaser", "{brand}_BlackFriday_Live",
]
EMAIL_SUBJECT_LINES = [
    "New In: {cat} you'll love 💕", "Your basket misses you! 🛒",
    "Welcome to {brand}! Here's 10% off", "We miss you! Come back for 20% off",
    "VIP Early Access: Sale starts NOW 🔥", "Just dropped: {cat} edit",
    "SALE: Up to 60% off everything", "Happy Birthday! 🎂 Here's a treat",
    "Complete the look: style picks for you", "⚡ Flash Sale: 24 hours only",
    "Your {brand} payday treat inside", "Don't miss out: {cat} selling fast",
]

INFLUENCER_TIERS = {
    "Mega":  {"followers_range": (1000000, 5000000), "cost_range": (5000, 25000), "weight": 5},
    "Macro": {"followers_range": (100000, 999999),   "cost_range": (1000, 5000),  "weight": 15},
    "Micro": {"followers_range": (10000, 99999),     "cost_range": (200, 1000),   "weight": 50},
    "Nano":  {"followers_range": (1000, 9999),        "cost_range": (50, 200),    "weight": 30},
}
INFLUENCER_PLATFORMS = ["Instagram", "TikTok", "YouTube"]
INFLUENCER_PLATFORM_WEIGHTS = [45, 40, 15]
INFLUENCER_CONTENT_TYPES = ["Reel", "Story", "Post", "TikTok", "YouTube Short", "Haul Video", "GRWM", "Try-On"]
INFLUENCER_NAMES = [
    "SophStyleUK", "OliviaOOTD", "ChloeFashionDiary", "MiaMakeupStyle",
    "RubyRoseStyle", "GraceGlam", "EllaEditorial", "DaisyDresscode",
    "LilyLookbook", "FreyaFashion", "JadeJournal", "HollyHauls",
    "ZaraZone", "PhoebePicks", "AmberAccessories", "BellaBasics",
    "LunaLuxe", "IvyInfluence", "PoppiePicks", "WillowWears",
    "JamesStyleMcr", "OliverOutfits", "HarryHauls", "CharlieClothes",
    "FinnFashion", "LeoLooksMCR", "OscarOutfitter", "GeorgeGarms",
]
