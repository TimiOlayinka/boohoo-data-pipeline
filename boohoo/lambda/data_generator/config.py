"""Brand/source configuration for Boohoo Group data generation."""

# Brand → Source → Datasets mapping
# Each brand uses different e-commerce platforms (realistic post-acquisition tech debt)
BRAND_SOURCES = {
    "boohoo": {
        "source": "boohoo_commerce",
        "customers_per": 1500, "products_per": 150, "orders_per": 15000,
    },
    "boohoo_man": {
        "source": "boohoo_commerce",
        "customers_per": 800, "products_per": 80, "orders_per": 8000,
    },
    "prettylittlething": {
        "source": "salesforce_commerce",
        "customers_per": 1200, "products_per": 120, "orders_per": 12000,
    },
    "nastygal": {
        "source": "shopify",
        "customers_per": 600, "products_per": 60, "orders_per": 6000,
    },
    "karen_millen": {
        "source": "magento",
        "customers_per": 400, "products_per": 50, "orders_per": 4000,
    },
    "coast": {
        "source": "magento",
        "customers_per": 300, "products_per": 40, "orders_per": 3000,
    },
    "debenhams": {
        "source": "oracle_commerce",
        "customers_per": 700, "products_per": 80, "orders_per": 7000,
    },
}

# Each source system has different field names (realistic!)
# This is what makes the DWH modeling challenge real
PRODUCT_SCHEMAS = {
    "boohoo_commerce": {
        "id_field": "sku", "name_field": "product_name",
        "color_field": "colour", "size_field": "size",
        "price_field": "selling_price", "cost_field": "cost_price",
        "cat_field": "department", "subcat_field": "product_type",
        "extra_fields": ["material", "season_code", "supplier_code", "weight_kg"],
    },
    "salesforce_commerce": {
        "id_field": "product_id", "name_field": "display_name",
        "color_field": "c_color", "size_field": "c_size",
        "price_field": "price_book_price", "cost_field": "c_cost",
        "cat_field": "primary_category_id", "subcat_field": "classification_category",
        "extra_fields": ["c_fabric_composition", "c_season", "c_vendor_id", "c_weight"],
    },
    "shopify": {
        "id_field": "variant_id", "name_field": "title",
        "color_field": "option1", "size_field": "option2",
        "price_field": "price", "cost_field": "cost",
        "cat_field": "product_type", "subcat_field": "tags",
        "extra_fields": ["vendor", "created_at", "inventory_quantity", "weight"],
    },
    "magento": {
        "id_field": "entity_id", "name_field": "name",
        "color_field": "color_attribute", "size_field": "size_attribute",
        "price_field": "price", "cost_field": "cost",
        "cat_field": "category_name", "subcat_field": "subcategory_name",
        "extra_fields": ["manufacturer", "season", "supplier_sku", "weight"],
    },
    "oracle_commerce": {
        "id_field": "item_id", "name_field": "display_name",
        "color_field": "colour_code", "size_field": "size_code",
        "price_field": "list_price", "cost_field": "unit_cost",
        "cat_field": "category_code", "subcat_field": "sub_category_code",
        "extra_fields": ["fabric_type", "season_year", "vendor_number", "gross_weight"],
    },
}

ORDER_SCHEMAS = {
    "boohoo_commerce": {
        "id_field": "order_id", "cust_field": "customer_id",
        "date_field": "order_date", "total_field": "order_total",
        "status_field": "order_status", "payment_field": "payment_method",
        "extra_fields": ["promo_code", "delivery_method", "warehouse_id"],
    },
    "salesforce_commerce": {
        "id_field": "order_no", "cust_field": "customer_no",
        "date_field": "creation_date", "total_field": "order_total",
        "status_field": "status", "payment_field": "payment_instrument",
        "extra_fields": ["coupon_code", "shipment_method_id", "site_id"],
    },
    "shopify": {
        "id_field": "id", "cust_field": "customer_id",
        "date_field": "created_at", "total_field": "total_price",
        "status_field": "financial_status", "payment_field": "gateway",
        "extra_fields": ["discount_codes", "fulfillment_status", "source_name"],
    },
    "magento": {
        "id_field": "increment_id", "cust_field": "customer_id",
        "date_field": "created_at", "total_field": "grand_total",
        "status_field": "status", "payment_field": "payment_method",
        "extra_fields": ["coupon_code", "shipping_method", "store_id"],
    },
    "oracle_commerce": {
        "id_field": "order_number", "cust_field": "profile_id",
        "date_field": "submitted_date", "total_field": "price_total",
        "status_field": "state", "payment_field": "payment_type",
        "extra_fields": ["promotion_code", "shipping_method", "site_code"],
    },
}

CUSTOMER_SCHEMAS = {
    "boohoo_commerce": {
        "id_field": "customer_id", "email_field": "email",
        "first_field": "first_name", "last_field": "last_name",
        "extra_fields": ["phone", "city", "country", "segment", "signup_date", "gender", "is_subscribed"],
    },
    "salesforce_commerce": {
        "id_field": "customer_no", "email_field": "email",
        "first_field": "first_name", "last_field": "last_name",
        "extra_fields": ["phone_home", "city", "country_code", "customer_group", "creation_date", "gender", "email_opt_in"],
    },
    "shopify": {
        "id_field": "id", "email_field": "email",
        "first_field": "first_name", "last_field": "last_name",
        "extra_fields": ["phone", "city", "country", "tags", "created_at", "accepts_marketing", "orders_count"],
    },
    "magento": {
        "id_field": "entity_id", "email_field": "email",
        "first_field": "firstname", "last_field": "lastname",
        "extra_fields": ["telephone", "city", "country_id", "group_id", "created_at", "gender", "is_subscribed"],
    },
    "oracle_commerce": {
        "id_field": "profile_id", "email_field": "email_address",
        "first_field": "first_name", "last_field": "last_name",
        "extra_fields": ["phone_number", "city", "country", "customer_segment", "registration_date", "gender", "receive_email"],
    },
}

CATEGORIES = {
    "Dresses": ["Midi Dresses","Maxi Dresses","Mini Dresses","Bodycon Dresses","Wrap Dresses","Shirt Dresses"],
    "Tops": ["T-Shirts","Blouses","Crop Tops","Bodysuits","Cami Tops","Shirts"],
    "Bottoms": ["Jeans","Trousers","Leggings","Shorts","Skirts","Joggers"],
    "Outerwear": ["Jackets","Coats","Blazers","Puffer Jackets","Denim Jackets","Bomber Jackets"],
    "Knitwear": ["Jumpers","Cardigans","Knitted Dresses","Roll Necks","Oversized Knits"],
    "Swimwear": ["Bikinis","Swimsuits","Cover Ups","Beach Dresses","Sarongs"],
    "Activewear": ["Sports Bras","Leggings","Gym Tops","Running Shorts","Tracksuits"],
    "Shoes": ["Heels","Boots","Trainers","Sandals","Flats","Platforms"],
    "Accessories": ["Bags","Jewellery","Sunglasses","Belts","Scarves","Hats"],
}

COLOURS = ["Black","White","Red","Pink","Blue","Navy","Green","Khaki","Beige","Cream",
           "Grey","Orange","Yellow","Lilac","Purple","Coral","Teal","Burgundy","Stone","Camel"]
MATERIALS = ["Polyester","Cotton","Viscose","Nylon","Elastane Blend","Jersey","Denim","Satin","Chiffon","Knit"]
SIZES_NUMERIC = ["4","6","8","10","12","14","16","18"]
SIZES_ALPHA = ["XS","S","M","L","XL","XXL"]
SIZES_SHOES = ["3","4","5","6","7","8"]

FIRST_F = ["Emily","Sophie","Olivia","Jessica","Chloe","Mia","Lucy","Grace","Ruby","Ella",
           "Amelia","Lily","Charlotte","Daisy","Freya","Holly","Zara","Phoebe","Jade","Lauren"]
FIRST_M = ["James","Oliver","Jack","Harry","Charlie","Thomas","George","Oscar","William","Noah",
           "Leo","Freddie","Henry","Jacob","Ethan","Samuel","Daniel","Mohammed","Liam","Finn"]
LAST_NAMES = ["Smith","Jones","Williams","Taylor","Brown","Davies","Evans","Wilson","Thomas","Roberts",
              "Johnson","Lewis","Walker","Robinson","White","Harris","Cooper","King","Patel","Khan"]

CITIES = [("London","GB"),("Manchester","GB"),("Birmingham","GB"),("Leeds","GB"),("Liverpool","GB"),
          ("Bristol","GB"),("Edinburgh","GB"),("Glasgow","GB"),("Cardiff","GB"),("Belfast","GB"),
          ("Dublin","IE"),("Paris","FR"),("Amsterdam","NL"),("Berlin","DE"),("New York","US"),("LA","US")]

STATUSES_MAP = {
    "boohoo_commerce": ["delivered","shipped","processing","returned","cancelled"],
    "salesforce_commerce": ["COMPLETED","SHIPPED","CREATED","RETURNED","CANCELLED"],
    "shopify": ["paid","partially_paid","pending","refunded","voided"],
    "magento": ["complete","shipped","processing","closed","canceled"],
    "oracle_commerce": ["SETTLED","SUBMITTED","PENDING_MERCHANT","RETURNED","REMOVED"],
}

PAYMENTS_MAP = {
    "boohoo_commerce": ["card","klarna","paypal","apple_pay","google_pay"],
    "salesforce_commerce": ["CREDIT_CARD","KLARNA","PAYPAL","APPLE_PAY","GIFT_CERTIFICATE"],
    "shopify": ["shopify_payments","klarna","paypal","manual","gift_card"],
    "magento": ["braintree","klarna_pay_later","paypal_express","stripe","checkmo"],
    "oracle_commerce": ["creditCard","klarnaPayment","payPal","applePay","giftCard"],
}

# ══════════════════════════════════════════════════════════════════════════════
# MARKETING CHANNEL CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

# Budget allocation per brand (weekly GBP spend across channels)
BRAND_MARKETING_BUDGETS = {
    "boohoo":            {"meta": 35000, "google": 45000, "tiktok": 15000, "email": 2000, "influencer": 8000},
    "boohoo_man":        {"meta": 18000, "google": 22000, "tiktok": 10000, "email": 1200, "influencer": 4000},
    "prettylittlething": {"meta": 55000, "google": 40000, "tiktok": 30000, "email": 3000, "influencer": 20000},
    "nastygal":          {"meta": 12000, "google": 10000, "tiktok": 18000, "email": 1000, "influencer": 6000},
    "karen_millen":      {"meta":  8000, "google": 12000, "tiktok":  3000, "email":  800, "influencer": 5000},
    "coast":             {"meta":  5000, "google":  8000, "tiktok":  2000, "email":  600, "influencer": 3000},
    "debenhams":         {"meta": 15000, "google": 25000, "tiktok":  5000, "email": 1500, "influencer": 2000},
}

# ── Meta Ads ──────────────────────────────────────────────────────────────────
META_ADS_OBJECTIVES = ["OUTCOME_TRAFFIC", "OUTCOME_SALES", "OUTCOME_AWARENESS", "OUTCOME_ENGAGEMENT"]
META_ADS_PUBLISHER_PLATFORMS = ["facebook", "instagram", "audience_network"]
META_ADS_CAMPAIGN_TEMPLATES = [
    "{brand}_SS25_Dresses_Conversions", "{brand}_AW24_NewIn_Traffic",
    "{brand}_Retargeting_DPA_Conversions", "{brand}_Lookalike_Prospecting",
    "{brand}_Brand_Awareness_Reach", "{brand}_Sale_Event_Conversions",
    "{brand}_VIP_Engagement_Custom", "{brand}_Summer_Collection_Traffic",
    "{brand}_BlackFriday_DPA_Sales", "{brand}_Payday_Push_Conversions",
]

# ── Google Ads ────────────────────────────────────────────────────────────────
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

# ── TikTok Ads ────────────────────────────────────────────────────────────────
TIKTOK_ADS_OBJECTIVES = ["CONVERSIONS", "TRAFFIC", "REACH", "VIDEO_VIEWS", "APP_PROMOTION"]
TIKTOK_ADS_CAMPAIGN_TEMPLATES = [
    "{brand}_SparkAds_Conversions", "{brand}_TopView_Awareness",
    "{brand}_InFeed_Traffic", "{brand}_Collection_DPA",
    "{brand}_Branded_Hashtag_Challenge", "{brand}_UGC_Engagement",
    "{brand}_Sale_Retargeting", "{brand}_NewIn_Prospecting",
]

# ── GA4 Sessions ──────────────────────────────────────────────────────────────
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
GA4_TRAFFIC_WEIGHTS = [20, 15, 15, 10, 8, 10, 12, 5, 2, 1, 1, 1]  # distribution
GA4_DEVICES = ["mobile", "desktop", "tablet"]
GA4_DEVICE_WEIGHTS = [62, 30, 8]
GA4_LANDING_PAGES = [
    "/", "/new-in", "/dresses", "/tops", "/sale", "/shoes",
    "/collections/summer", "/collections/party", "/bestsellers",
    "/category/{cat}", "/product/{product_id}",
]

# ── Email / CRM ───────────────────────────────────────────────────────────────
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

# ── Influencer Marketing ──────────────────────────────────────────────────────
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
