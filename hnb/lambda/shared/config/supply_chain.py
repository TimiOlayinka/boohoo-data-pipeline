"""Supply Chain and Fulfilment mock data schema configurations."""

SUPPLY_CHAIN_SCHEMAS = {
    "warehouse_status": {
        "filename": "warehouse_status.jsonl.gz",
        "fields": ["status_id", "basket_id", "warehouse_location", "status", "picker_id", "timestamp"]
    },
    "parcel_events": {
        "filename": "parcel_events.jsonl.gz",
        "fields": ["event_id", "parcel_id", "delivery_id", "carrier", "event_type", "location", "event_timestamp"]
    },
    "customer_otif": {
        "filename": "customer_otif.jsonl.gz",
        "fields": ["otif_id", "order_id", "customer_id", "promised_date", "actual_delivery_date", "is_on_time", "is_in_full", "defect_reason"]
    },
    "customer_otif_cc": {
        "filename": "customer_otif_cc.jsonl.gz",
        "fields": ["otif_cc_id", "order_id", "contact_center_agent_id", "override_reason", "override_timestamp"]
    },
    "postship_defect": {
        "filename": "postship_defect.jsonl.gz",
        "fields": ["defect_id", "order_id", "parcel_id", "defect_type", "severity", "reported_date"]
    },
    "digital_refunds": {
        "filename": "digital_refunds.jsonl.gz",
        "fields": ["refund_id", "order_id", "customer_id", "refund_amount", "refund_reason", "status", "processed_date"]
    },
    "delivery_order": {
        "filename": "delivery_order.jsonl.gz",
        "fields": ["delivery_id", "order_id", "customer_id", "shipping_address", "carrier", "service_level", "estimated_delivery_date"]
    },
    "delivery_item": {
        "filename": "delivery_item.jsonl.gz",
        "fields": ["delivery_item_id", "delivery_id", "item_sku", "quantity", "status"]
    },
    "basket_items": {
        "filename": "basket_items.jsonl.gz",
        "fields": ["basket_item_id", "basket_id", "item_sku", "quantity", "unit_price", "added_timestamp"]
    }
}
