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
