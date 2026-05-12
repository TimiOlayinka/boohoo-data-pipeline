"""Generate all dbt models for HNB Customer Experience & Supply Chain domains.
  rdl_{source} → history dedup + field normalization
  odl          → star schema (dim_*, fact_*)
  adl/bi       → materialized views for dashboards
"""
import os

BASE = r"d:\BellosData\aws-data-portfolio\hnb\dbt\models"

# RDL Schemas
RDL_MODELS = {
    "zendesk": [
        ("tickets", "ticket_id, customer_id, order_id, status, priority, subject, created_at, updated_at, agent_id, team_id", "ticket_id"),
        ("agents", "agent_id, name, email, team_id, status, created_at", "agent_id"),
        ("teams", "team_id, team_name, tier, specialty", "team_id"),
        ("ticket_interactions", "interaction_id, ticket_id, agent_id, customer_id, channel, message_length, sentiment_score, interaction_timestamp", "interaction_id"),
    ],
    "qualtrics": [
        ("blnx_survey", "survey_id, ticket_id, customer_id, agent_id, csat_score, resolution_score, effort_score, comments, survey_date", "survey_id"),
        ("nps_visitview", "response_id, customer_id, order_id, nps_score, nps_category, feedback_text, device_type, response_date", "response_id"),
    ],
    "manhattan": [
        ("warehouse_status", "status_id, basket_id, warehouse_location, status, picker_id, timestamp", "status_id"),
        ("basket_items", "basket_item_id, basket_id, item_sku, quantity, unit_price, added_timestamp", "basket_item_id"),
    ],
    "metapack": [
        ("parcel_events", "event_id, parcel_id, delivery_id, carrier, event_type, location, event_timestamp", "event_id"),
        ("delivery_order", "delivery_id, order_id, customer_id, shipping_address, carrier, service_level, estimated_delivery_date", "delivery_id"),
        ("delivery_item", "delivery_item_id, delivery_id, item_sku, quantity, status", "delivery_item_id"),
        ("digital_refunds", "refund_id, order_id, customer_id, refund_amount, refund_reason, status, processed_date", "refund_id"),
    ],
    "hnb_commerce": [
        ("customer_otif", "otif_id, order_id, customer_id, promised_date, actual_delivery_date, is_on_time, is_in_full, defect_reason", "otif_id"),
        ("customer_otif_cc", "otif_cc_id, order_id, contact_center_agent_id, override_reason, override_timestamp", "otif_cc_id"),
        ("postship_defect", "defect_id, order_id, parcel_id, defect_type, severity, reported_date", "defect_id"),
    ]
}

def rdl_sql(source, model, fields, pk):
    return f"""------------------------------------------------------------------------------------------------------------------------
-- rdl_{source}.{model}
-- Deduplicated from {model}_history
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT {fields},
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM {{{{ source('rdl_{source}', '{model}_history') }}}}
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY {pk} ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT {fields}, '{source}' AS source_system, ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
"""

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    print(f"  {os.path.relpath(path, BASE)}")

print("RDL models:")
for src, models in RDL_MODELS.items():
    for model, fields, pk in models:
        write(os.path.join(BASE, "rdl", src, f"rdl_{model}.sql"), rdl_sql(src, model, fields, pk))

print("\nODL models:")

# Helper function for ODL models
def odl_sql(layer_type, model_name, fields, rdl_source_model, pk_logic=None):
    if pk_logic:
        select_clause = f"{pk_logic},\n    {fields}"
    else:
        select_clause = fields

    return f"""------------------------------------------------------------------------------------------------------------------------
-- odl.{layer_type}.{model_name}
------------------------------------------------------------------------------------------------------------------------
WITH base AS (
    SELECT * FROM {{{{ ref('{rdl_source_model}') }}}}
)
SELECT
    {select_clause},
    CURRENT_TIMESTAMP AS dwh_created_at
FROM base
"""

# Dimensions
write(os.path.join(BASE, "odl", "dim", "dim_tickets.sql"), odl_sql("dim", "dim_tickets", "ticket_id AS ticket_nk, customer_id, order_id, status, priority, subject, created_at, updated_at", "rdl_tickets", "MD5(ticket_id) AS ticket_sk"))
write(os.path.join(BASE, "odl", "dim", "dim_agents.sql"), odl_sql("dim", "dim_agents", "agent_id AS agent_nk, name, email, team_id, status, created_at", "rdl_agents", "MD5(agent_id) AS agent_sk"))
write(os.path.join(BASE, "odl", "dim", "dim_teams.sql"), odl_sql("dim", "dim_teams", "team_id AS team_nk, team_name, tier, specialty", "rdl_teams", "MD5(team_id) AS team_sk"))

# Facts
write(os.path.join(BASE, "odl", "fact", "fact_ticket_interactions.sql"), odl_sql("fact", "fact_ticket_interactions", "interaction_id, MD5(ticket_id) AS ticket_sk, MD5(agent_id) AS agent_sk, customer_id, channel, message_length, sentiment_score, interaction_timestamp", "rdl_ticket_interactions"))
write(os.path.join(BASE, "odl", "fact", "fact_ticket_blnx_survey.sql"), odl_sql("fact", "fact_ticket_blnx_survey", "survey_id, MD5(ticket_id) AS ticket_sk, MD5(agent_id) AS agent_sk, customer_id, csat_score, resolution_score, effort_score, comments, survey_date", "rdl_blnx_survey"))
write(os.path.join(BASE, "odl", "fact", "fact_nps_visitview.sql"), odl_sql("fact", "fact_nps_visitview", "response_id, customer_id, order_id, nps_score, nps_category, feedback_text, device_type, response_date", "rdl_nps_visitview"))
write(os.path.join(BASE, "odl", "fact", "fact_basket_warehouse_status.sql"), odl_sql("fact", "fact_basket_warehouse_status", "status_id, basket_id, warehouse_location, status, picker_id, timestamp", "rdl_warehouse_status"))
write(os.path.join(BASE, "odl", "fact", "fact_parcel_events.sql"), odl_sql("fact", "fact_parcel_events", "event_id, parcel_id, delivery_id, carrier, event_type, location, event_timestamp", "rdl_parcel_events"))
write(os.path.join(BASE, "odl", "fact", "fact_customer_otif.sql"), odl_sql("fact", "fact_customer_otif", "otif_id, order_id, customer_id, promised_date, actual_delivery_date, is_on_time, is_in_full, defect_reason", "rdl_customer_otif"))
write(os.path.join(BASE, "odl", "fact", "fact_customer_otif_cc.sql"), odl_sql("fact", "fact_customer_otif_cc", "otif_cc_id, order_id, contact_center_agent_id, override_reason, override_timestamp", "rdl_customer_otif_cc"))
write(os.path.join(BASE, "odl", "fact", "fact_postship_defect.sql"), odl_sql("fact", "fact_postship_defect", "defect_id, order_id, parcel_id, defect_type, severity, reported_date", "rdl_postship_defect"))
write(os.path.join(BASE, "odl", "fact", "fact_digital_refunds.sql"), odl_sql("fact", "fact_digital_refunds", "refund_id, order_id, customer_id, refund_amount, refund_reason, status, processed_date", "rdl_digital_refunds"))
write(os.path.join(BASE, "odl", "fact", "fact_delivery_order.sql"), odl_sql("fact", "fact_delivery_order", "delivery_id, order_id, customer_id, shipping_address, carrier, service_level, estimated_delivery_date", "rdl_delivery_order"))
write(os.path.join(BASE, "odl", "fact", "fact_delivery_item.sql"), odl_sql("fact", "fact_delivery_item", "delivery_item_id, delivery_id, item_sku, quantity, status", "rdl_delivery_item"))
write(os.path.join(BASE, "odl", "fact", "fact_basket_items.sql"), odl_sql("fact", "fact_basket_items", "basket_item_id, basket_id, item_sku, quantity, unit_price, added_timestamp", "rdl_basket_items"))


print("\nADL/BI models:")

# fact_cx_nps_summary
adl_nps = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_cx_nps_summary
------------------------------------------------------------------------------------------------------------------------
SELECT
    response_date AS date,
    device_type,
    nps_category,
    COUNT(response_id) AS total_responses,
    ROUND(AVG(nps_score), 2) AS avg_nps_score
FROM {{ ref('fact_nps_visitview') }}
GROUP BY 1, 2, 3
"""
write(os.path.join(BASE, "adl", "bi", "fact_cx_nps_summary.sql"), adl_nps)

# fact_delivery_performance
adl_delivery = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_delivery_performance
------------------------------------------------------------------------------------------------------------------------
SELECT
    promised_date AS date,
    COUNT(otif_id) AS total_orders,
    SUM(CASE WHEN is_on_time = 'True' THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN is_in_full = 'True' THEN 1 ELSE 0 END) AS in_full_orders,
    defect_reason
FROM {{ ref('fact_customer_otif') }}
GROUP BY 1, 5
"""
write(os.path.join(BASE, "adl", "bi", "fact_delivery_performance.sql"), adl_delivery)

# fact_ticket_resolution
adl_ticket = """------------------------------------------------------------------------------------------------------------------------
-- bi.fact_ticket_resolution
------------------------------------------------------------------------------------------------------------------------
SELECT
    t.created_at::DATE AS date,
    t.priority,
    t.status,
    a.team_nk AS team_id,
    COUNT(t.ticket_nk) AS total_tickets,
    ROUND(AVG(s.csat_score), 2) AS avg_csat,
    ROUND(AVG(s.resolution_score), 2) AS avg_resolution
FROM {{ ref('dim_tickets') }} t
LEFT JOIN {{ ref('fact_ticket_blnx_survey') }} s ON t.ticket_sk = s.ticket_sk
LEFT JOIN {{ ref('dim_agents') }} a ON t.agent_id = a.agent_nk
GROUP BY 1, 2, 3, 4
"""
write(os.path.join(BASE, "adl", "bi", "fact_ticket_resolution.sql"), adl_ticket)

print("\nAll models generated.")
