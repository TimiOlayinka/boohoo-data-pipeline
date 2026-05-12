"""
HNB Customer Experience & Supply Chain Data Quality & Lineage Explorer
======================================================================
Interactive engineering tool for monitoring data quality,
freshness, cost, and lineage across all warehouse layers.

Run:  python app.py
Open: http://localhost:5000
"""
from flask import Flask, jsonify, send_from_directory
import os

app = Flask(__name__, static_folder="static")
PORT = 5000

# ─────────────────────────────────────────────
# Model Registry
# ─────────────────────────────────────────────

MODELS = {
    # ── RDL Layer ──
    "rdl_tickets": {"layer":"rdl","domain":"zendesk","entity":"tickets","brand":"HNB","rows":15000,"columns":10,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":1.5,"upstream":["source:zendesk_tickets"],"downstream":["dim_tickets"]},
    "rdl_agents": {"layer":"rdl","domain":"zendesk","entity":"agents","brand":"HNB","rows":150,"columns":6,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":1.0,"upstream":["source:zendesk_agents"],"downstream":["dim_agents"]},
    "rdl_teams": {"layer":"rdl","domain":"zendesk","entity":"teams","brand":"HNB","rows":10,"columns":4,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":1.0,"upstream":["source:zendesk_teams"],"downstream":["dim_teams"]},
    "rdl_ticket_interactions": {"layer":"rdl","domain":"zendesk","entity":"interactions","brand":"HNB","rows":45000,"columns":8,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.08,"versions_avg":1.8,"upstream":["source:zendesk_ticket_interactions"],"downstream":["fact_ticket_interactions"]},
    
    "rdl_blnx_survey": {"layer":"rdl","domain":"qualtrics","entity":"surveys","brand":"HNB","rows":5000,"columns":9,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":1.2,"upstream":["source:qualtrics_blnx_survey"],"downstream":["fact_ticket_blnx_survey"]},
    "rdl_nps_visitview": {"layer":"rdl","domain":"qualtrics","entity":"surveys","brand":"HNB","rows":12000,"columns":8,"freshness":"2h","status":"warn","tests_pass":2,"tests_fail":0,"tests_warn":1,"cost_day":0.04,"versions_avg":1.1,"upstream":["source:qualtrics_nps_visitview"],"downstream":["fact_nps_visitview"]},
    
    "rdl_warehouse_status": {"layer":"rdl","domain":"manhattan","entity":"warehouse","brand":"HNB","rows":125000,"columns":6,"freshness":"30m","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.15,"versions_avg":2.5,"upstream":["source:manhattan_warehouse_status"],"downstream":["fact_basket_warehouse_status"]},
    "rdl_basket_items": {"layer":"rdl","domain":"manhattan","entity":"baskets","brand":"HNB","rows":250000,"columns":6,"freshness":"30m","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.18,"versions_avg":1.9,"upstream":["source:manhattan_basket_items"],"downstream":["fact_basket_items"]},
    
    "rdl_parcel_events": {"layer":"rdl","domain":"metapack","entity":"parcels","brand":"HNB","rows":340000,"columns":7,"freshness":"15m","status":"pass","tests_pass":4,"tests_fail":0,"tests_warn":0,"cost_day":0.25,"versions_avg":3.1,"upstream":["source:metapack_parcel_events"],"downstream":["fact_parcel_events"]},
    "rdl_delivery_order": {"layer":"rdl","domain":"metapack","entity":"deliveries","brand":"HNB","rows":85000,"columns":7,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.09,"versions_avg":1.2,"upstream":["source:metapack_delivery_order"],"downstream":["fact_delivery_order"]},
    "rdl_delivery_item": {"layer":"rdl","domain":"metapack","entity":"deliveries","brand":"HNB","rows":190000,"columns":5,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.12,"versions_avg":1.1,"upstream":["source:metapack_delivery_item"],"downstream":["fact_delivery_item"]},
    "rdl_digital_refunds": {"layer":"rdl","domain":"metapack","entity":"refunds","brand":"HNB","rows":4500,"columns":7,"freshness":"4h","status":"warn","tests_pass":2,"tests_fail":0,"tests_warn":1,"cost_day":0.02,"versions_avg":1.0,"upstream":["source:metapack_digital_refunds"],"downstream":["fact_digital_refunds"]},
    
    "rdl_customer_otif": {"layer":"rdl","domain":"hnb_commerce","entity":"otif","brand":"HNB","rows":82000,"columns":8,"freshness":"4h","status":"fail","tests_pass":2,"tests_fail":1,"tests_warn":0,"cost_day":0.08,"versions_avg":1.1,"upstream":["source:hnb_customer_otif"],"downstream":["fact_customer_otif"]},
    "rdl_customer_otif_cc": {"layer":"rdl","domain":"hnb_commerce","entity":"otif","brand":"HNB","rows":1200,"columns":5,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":1.0,"upstream":["source:hnb_customer_otif_cc"],"downstream":["fact_customer_otif_cc"]},
    "rdl_postship_defect": {"layer":"rdl","domain":"hnb_commerce","entity":"defects","brand":"HNB","rows":3400,"columns":6,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":1.0,"upstream":["source:hnb_postship_defect"],"downstream":["fact_postship_defect"]},

    # ── ODL Layer ──
    "dim_tickets": {"layer":"odl","domain":"conformed","entity":"dimension","brand":"HNB","rows":15000,"columns":8,"freshness":"1h","status":"pass","tests_pass":4,"tests_fail":0,"tests_warn":0,"cost_day":0.06,"versions_avg":0,"upstream":["rdl_tickets"],"downstream":["fact_ticket_interactions", "fact_ticket_blnx_survey", "fact_ticket_resolution"]},
    "dim_agents": {"layer":"odl","domain":"conformed","entity":"dimension","brand":"HNB","rows":150,"columns":6,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":["rdl_agents"],"downstream":["fact_ticket_interactions", "fact_ticket_blnx_survey", "fact_ticket_resolution"]},
    "dim_teams": {"layer":"odl","domain":"conformed","entity":"dimension","brand":"HNB","rows":10,"columns":4,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":["rdl_teams"],"downstream":[]},
    
    "fact_ticket_interactions": {"layer":"odl","domain":"cx","entity":"fact","brand":"HNB","rows":45000,"columns":8,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.09,"versions_avg":0,"upstream":["rdl_ticket_interactions", "dim_tickets", "dim_agents"],"downstream":[]},
    "fact_ticket_blnx_survey": {"layer":"odl","domain":"cx","entity":"fact","brand":"HNB","rows":5000,"columns":9,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":0,"upstream":["rdl_blnx_survey", "dim_tickets", "dim_agents"],"downstream":["fact_ticket_resolution"]},
    "fact_nps_visitview": {"layer":"odl","domain":"cx","entity":"fact","brand":"HNB","rows":12000,"columns":8,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":0,"upstream":["rdl_nps_visitview"],"downstream":["fact_cx_nps_summary"]},
    
    "fact_basket_warehouse_status": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":125000,"columns":6,"freshness":"30m","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.16,"versions_avg":0,"upstream":["rdl_warehouse_status"],"downstream":[]},
    "fact_parcel_events": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":340000,"columns":7,"freshness":"15m","status":"pass","tests_pass":4,"tests_fail":0,"tests_warn":0,"cost_day":0.28,"versions_avg":0,"upstream":["rdl_parcel_events"],"downstream":[]},
    "fact_customer_otif": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":82000,"columns":8,"freshness":"4h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.10,"versions_avg":0,"upstream":["rdl_customer_otif"],"downstream":["fact_delivery_performance"]},
    "fact_customer_otif_cc": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":1200,"columns":5,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["rdl_customer_otif_cc"],"downstream":[]},
    "fact_postship_defect": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":3400,"columns":6,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["rdl_postship_defect"],"downstream":[]},
    "fact_digital_refunds": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":4500,"columns":7,"freshness":"4h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["rdl_digital_refunds"],"downstream":[]},
    "fact_delivery_order": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":85000,"columns":7,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.10,"versions_avg":0,"upstream":["rdl_delivery_order"],"downstream":[]},
    "fact_delivery_item": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":190000,"columns":5,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.14,"versions_avg":0,"upstream":["rdl_delivery_item"],"downstream":[]},
    "fact_basket_items": {"layer":"odl","domain":"supply_chain","entity":"fact","brand":"HNB","rows":250000,"columns":6,"freshness":"30m","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.20,"versions_avg":0,"upstream":["rdl_basket_items"],"downstream":[]},

    # ── ADL Layer ──
    "fact_cx_nps_summary":  {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"HNB","rows":365,"columns":5,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["fact_nps_visitview"],"downstream":[]},
    "fact_delivery_performance": {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"HNB","rows":730,"columns":5,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":0,"upstream":["fact_customer_otif"],"downstream":[]},
    "fact_ticket_resolution": {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"HNB","rows":1095,"columns":7,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":0,"upstream":["dim_tickets", "fact_ticket_blnx_survey", "dim_agents"],"downstream":[]},
}

# ─────────────────────────────────────────────
# Per-Model Test Details
# ─────────────────────────────────────────────

TEST_DETAILS = {
    "rdl_nps_visitview": [
        {"test": "not_null", "column": "response_id", "status": "pass", "severity": "error", "message": None, "sql": "SELECT count(*) FROM rdl_qualtrics.rdl_nps_visitview WHERE response_id IS NULL"},
        {"test": "unique", "column": "response_id", "status": "pass", "severity": "error", "message": None, "sql": "SELECT response_id, count(*) FROM rdl_qualtrics.rdl_nps_visitview GROUP BY 1 HAVING count(*) > 1"},
        {"test": "accepted_values", "column": "device_type", "status": "warn", "severity": "warn", "message": "Unexpected device type 'UNKNOWN' found in 45 rows.", "sql": "SELECT device_type, count(*) FROM rdl_qualtrics.rdl_nps_visitview GROUP BY 1"},
    ],
    "rdl_customer_otif": [
        {"test": "not_null", "column": "otif_id", "status": "pass", "severity": "error", "message": None, "sql": "SELECT count(*) FROM rdl_hnb_commerce.rdl_customer_otif WHERE otif_id IS NULL"},
        {"test": "unique", "column": "otif_id", "status": "pass", "severity": "error", "message": None, "sql": "SELECT otif_id, count(*) FROM rdl_hnb_commerce.rdl_customer_otif GROUP BY 1 HAVING count(*) > 1"},
        {"test": "relationships", "column": "order_id", "status": "fail", "severity": "error", "message": "Found 120 OTIF records where order_id does not exist in master orders table. Upstream Commerce API missing data.", "sql": "SELECT count(*) FROM rdl_hnb_commerce.rdl_customer_otif o LEFT JOIN rdl_hnb_commerce.orders m ON o.order_id = m.order_id WHERE m.order_id IS NULL"},
    ],
    "rdl_digital_refunds": [
        {"test": "not_null", "column": "refund_id", "status": "pass", "severity": "error", "message": None, "sql": "SELECT count(*) FROM rdl_metapack.rdl_digital_refunds WHERE refund_id IS NULL"},
        {"test": "accepted_values", "column": "status", "status": "warn", "severity": "warn", "message": "Refund status 'Pending_Review' exceeding SLA threshold for 85 items.", "sql": "SELECT count(*) FROM rdl_metapack.rdl_digital_refunds WHERE status = 'Pending_Review' AND processed_date < CURRENT_DATE - 3"},
    ],
}

# Generate default test details for models not explicitly listed
for model_name, model_data in MODELS.items():
    if model_name not in TEST_DETAILS:
        tests = []
        pk = f"{model_data['entity']}_id" if model_data["entity"] not in ("aggregate",) else "id"
        if pk == "dimension_id": pk = "id"
        if pk == "fact_id": pk = "id"
        tests.append({"test": "not_null", "column": pk, "status": "pass", "severity": "error", "message": None, "sql": f"SELECT count(*) FROM {model_name} WHERE {pk} IS NULL"})
        tests.append({"test": "unique", "column": pk, "status": "pass", "severity": "error", "message": None, "sql": f"SELECT {pk}, count(*) FROM {model_name} GROUP BY 1 HAVING count(*) > 1"})
        TEST_DETAILS[model_name] = tests

# ─── Derive schema for each model ───
BUSINESS_DOMAIN_MAP = {
    "zendesk": "Customer Experience",
    "qualtrics": "Customer Experience",
    "cx": "Customer Experience",
    "manhattan": "Supply Chain",
    "metapack": "Supply Chain",
    "hnb_commerce": "Supply Chain",
    "supply_chain": "Supply Chain",
    "conformed": "Core Business",
    "analytics": "Analytics & BI",
}

for model_name, model_data in MODELS.items():
    model_data["business_domain"] = BUSINESS_DOMAIN_MAP.get(
        model_data["domain"], model_data["domain"]
    )

ALL_DOMAINS = sorted(set(m["business_domain"] for m in MODELS.values()))

# ─── API Routes ───

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.route("/api/domains")
def api_domains():
    return jsonify(ALL_DOMAINS)

@app.route("/api/summary")
def api_summary():
    all_models = list(MODELS.values())
    tp = sum(m["tests_pass"] for m in all_models)
    tf = sum(m["tests_fail"] for m in all_models)
    tw = sum(m["tests_warn"] for m in all_models)
    return jsonify({
        "total_models": len(MODELS),
        "total_rows": sum(m["rows"] for m in all_models),
        "tests_pass": tp, "tests_fail": tf, "tests_warn": tw,
        "pass_rate": round(tp / max(tp+tf+tw, 1) * 100, 1),
        "daily_cost": round(sum(m["cost_day"] for m in all_models), 2),
        "monthly_cost": round(sum(m["cost_day"] for m in all_models) * 30, 2),
        "layers": {
            layer: {
                "models": len([m for m in all_models if m["layer"] == layer]),
                "healthy": len([m for m in all_models if m["layer"] == layer and m["status"] == "pass"]),
                "warning": len([m for m in all_models if m["layer"] == layer and m["status"] == "warn"]),
                "failing": len([m for m in all_models if m["layer"] == layer and m["status"] == "fail"]),
                "cost": round(sum(m["cost_day"] for m in all_models if m["layer"] == layer) * 30, 2),
            }
            for layer in ("rdl", "odl", "adl")
        }
    })

@app.route("/api/models")
def api_models():
    return jsonify([{"name": k, **v} for k, v in MODELS.items()])

@app.route("/api/models/<name>")
def api_model_detail(name):
    m = MODELS.get(name)
    if not m:
        return jsonify({"error": "not found"}), 404
    return jsonify({"name": name, **m})

@app.route("/api/tests/<name>")
def api_tests(name):
    tests = TEST_DETAILS.get(name, [])
    return jsonify(tests)

@app.route("/api/lineage")
def api_lineage():
    nodes = []
    edges = []
    for name, m in MODELS.items():
        nodes.append({"id": name, "layer": m["layer"], "status": m["status"], "entity": m["entity"], "rows": m["rows"], "domain": m["business_domain"]})
        for up in m["upstream"]:
            if up.startswith("source:"):
                src_id = up
                nodes.append({"id": src_id, "layer": "source", "status": "pass", "entity": "source", "rows": 0, "domain": m["business_domain"]})
                edges.append({"from": src_id, "to": name})
            elif up in MODELS:
                edges.append({"from": up, "to": name})
    seen = set()
    unique_nodes = []
    for n in nodes:
        if n["id"] not in seen:
            unique_nodes.append(n)
            seen.add(n["id"])
    return jsonify({"nodes": unique_nodes, "edges": edges})

if __name__ == "__main__":
    print(f"HNB Data Quality & Lineage Explorer -> http://localhost:{PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=True)
