"""
Boohoo Data Quality & Lineage Explorer
=======================================
Interactive engineering tool for monitoring data quality,
freshness, cost, and lineage across all warehouse layers.

Features:
  - Interactive lineage graph (click nodes for detail)
  - Layer tabs: RDL → ODL → ADL
  - Test pass/fail/warn per model
  - Freshness & row count monitoring
  - Cost per model tracking
  - Side panel with model detail on click

Run:  python app.py
Open: http://localhost:5000
"""
from flask import Flask, jsonify, send_from_directory
import os

app = Flask(__name__, static_folder="static")
PORT = 5000

# ─────────────────────────────────────────────
# Model Registry (replaced by DuckDB in prod)
# ─────────────────────────────────────────────

MODELS = {
    # ── RDL Layer ──
    "boohoo_orders":        {"layer":"rdl","domain":"boohoo_commerce","entity":"orders","brand":"Boohoo","rows":125430,"columns":20,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.08,"versions_avg":2.3,"upstream":["source:boohoo_orders_history"],"downstream":["fact_orders"]},
    "boohoo_customers":     {"layer":"rdl","domain":"boohoo_commerce","entity":"customers","brand":"Boohoo","rows":48290,"columns":19,"freshness":"2h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":1,"cost_day":0.05,"versions_avg":1.8,"upstream":["source:boohoo_customers_history"],"downstream":["dim_customers"]},
    "boohoo_products":      {"layer":"rdl","domain":"boohoo_commerce","entity":"products","brand":"Boohoo","rows":15820,"columns":22,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":3.1,"upstream":["source:boohoo_products_history"],"downstream":["dim_products"]},
    "boohoo_man_orders":    {"layer":"rdl","domain":"boohoo_commerce","entity":"orders","brand":"BoohooMAN","rows":67200,"columns":20,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.07,"versions_avg":2.1,"upstream":["source:boohoo_man_orders_history"],"downstream":["fact_orders"]},
    "boohoo_man_customers": {"layer":"rdl","domain":"boohoo_commerce","entity":"customers","brand":"BoohooMAN","rows":22100,"columns":19,"freshness":"2h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":1.5,"upstream":["source:boohoo_man_customers_history"],"downstream":["dim_customers"]},
    "boohoo_man_products":  {"layer":"rdl","domain":"boohoo_commerce","entity":"products","brand":"BoohooMAN","rows":8400,"columns":22,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":2.8,"upstream":["source:boohoo_man_products_history"],"downstream":["dim_products"]},
    "plt_orders":           {"layer":"rdl","domain":"salesforce","entity":"orders","brand":"PLT","rows":98700,"columns":20,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.08,"versions_avg":2.5,"upstream":["source:plt_orders_history"],"downstream":["fact_orders"]},
    "plt_customers":        {"layer":"rdl","domain":"salesforce","entity":"customers","brand":"PLT","rows":41300,"columns":19,"freshness":"2h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":1.9,"upstream":["source:plt_customers_history"],"downstream":["dim_customers"]},
    "plt_products":         {"layer":"rdl","domain":"salesforce","entity":"products","brand":"PLT","rows":12900,"columns":22,"freshness":"2h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":3.4,"upstream":["source:plt_products_history"],"downstream":["dim_products"]},
    "nastygal_orders":      {"layer":"rdl","domain":"shopify","entity":"orders","brand":"NastyGal","rows":54300,"columns":20,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.06,"versions_avg":2.0,"upstream":["source:nastygal_orders_history"],"downstream":["fact_orders"]},
    "nastygal_customers":   {"layer":"rdl","domain":"shopify","entity":"customers","brand":"NastyGal","rows":28900,"columns":19,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":1.6,"upstream":["source:nastygal_customers_history"],"downstream":["dim_customers"]},
    "nastygal_products":    {"layer":"rdl","domain":"shopify","entity":"products","brand":"NastyGal","rows":9100,"columns":22,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":2.9,"upstream":["source:nastygal_products_history"],"downstream":["dim_products"]},
    "karen_millen_orders":  {"layer":"rdl","domain":"magento","entity":"orders","brand":"Karen Millen","rows":32100,"columns":20,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":1.7,"upstream":["source:karen_millen_orders_history"],"downstream":["fact_orders"]},
    "karen_millen_customers":{"layer":"rdl","domain":"magento","entity":"customers","brand":"Karen Millen","rows":18400,"columns":19,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":1.3,"upstream":["source:karen_millen_customers_history"],"downstream":["dim_customers"]},
    "karen_millen_products":{"layer":"rdl","domain":"magento","entity":"products","brand":"Karen Millen","rows":5200,"columns":22,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":2.4,"upstream":["source:karen_millen_products_history"],"downstream":["dim_products"]},
    "coast_orders":         {"layer":"rdl","domain":"magento","entity":"orders","brand":"Coast","rows":28700,"columns":20,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":1.6,"upstream":["source:coast_orders_history"],"downstream":["fact_orders"]},
    "coast_customers":      {"layer":"rdl","domain":"magento","entity":"customers","brand":"Coast","rows":15200,"columns":19,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":1.2,"upstream":["source:coast_customers_history"],"downstream":["dim_customers"]},
    "coast_products":       {"layer":"rdl","domain":"magento","entity":"products","brand":"Coast","rows":4800,"columns":22,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":2.2,"upstream":["source:coast_products_history"],"downstream":["dim_products"]},
    "debenhams_orders":     {"layer":"rdl","domain":"oracle","entity":"orders","brand":"Debenhams","rows":38400,"columns":20,"freshness":"3h","status":"warn","tests_pass":2,"tests_fail":0,"tests_warn":1,"cost_day":0.05,"versions_avg":1.4,"upstream":["source:debenhams_orders_history"],"downstream":["fact_orders"]},
    "debenhams_customers":  {"layer":"rdl","domain":"oracle","entity":"customers","brand":"Debenhams","rows":24600,"columns":19,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.04,"versions_avg":1.1,"upstream":["source:debenhams_customers_history"],"downstream":["dim_customers"]},
    "debenhams_products":   {"layer":"rdl","domain":"oracle","entity":"products","brand":"Debenhams","rows":7100,"columns":22,"freshness":"3h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":2.0,"upstream":["source:debenhams_products_history"],"downstream":["dim_products"]},
    "rdl_meta_ads":         {"layer":"rdl","domain":"marketing","entity":"ads","brand":"All","rows":89400,"columns":27,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.07,"versions_avg":1.4,"upstream":["source:meta_ads_history"],"downstream":["fact_meta_campaign_insights","dim_campaigns"]},
    "rdl_google_ads":       {"layer":"rdl","domain":"marketing","entity":"ads","brand":"All","rows":67200,"columns":31,"freshness":"3h","status":"warn","tests_pass":2,"tests_fail":0,"tests_warn":1,"cost_day":0.06,"versions_avg":1.3,"upstream":["source:google_ads_history"],"downstream":["fact_google_ads_performance","dim_campaigns"]},
    "rdl_tiktok_ads":       {"layer":"rdl","domain":"marketing","entity":"ads","brand":"All","rows":45100,"columns":31,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":1.2,"upstream":["source:tiktok_ads_history"],"downstream":["fact_tiktok_ad_insights","dim_campaigns"]},
    "rdl_ga4_sessions":     {"layer":"rdl","domain":"marketing","entity":"sessions","brand":"All","rows":234100,"columns":27,"freshness":"4h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.12,"versions_avg":1.0,"upstream":["source:ga4_sessions_history"],"downstream":["fact_ga4_sessions"]},
    "rdl_email_campaigns":  {"layer":"rdl","domain":"marketing","entity":"email","brand":"All","rows":12800,"columns":29,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":1.6,"upstream":["source:email_campaigns_history"],"downstream":["fact_email_engagement"]},
    "rdl_influencer_posts": {"layer":"rdl","domain":"marketing","entity":"influencer","brand":"All","rows":3200,"columns":32,"freshness":"3h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":2.1,"upstream":["source:influencer_posts_history"],"downstream":["fact_influencer_performance"]},

    # ── ODL Layer ──
    "dim_customers":          {"layer":"odl","domain":"conformed","entity":"dimension","brand":"All","rows":198750,"columns":16,"freshness":"1h","status":"pass","tests_pass":4,"tests_fail":0,"tests_warn":0,"cost_day":0.10,"versions_avg":0,"upstream":["boohoo_customers","boohoo_man_customers","plt_customers","nastygal_customers","karen_millen_customers","coast_customers","debenhams_customers"],"downstream":["fact_customer_segments"]},
    "dim_products":           {"layer":"odl","domain":"conformed","entity":"dimension","brand":"All","rows":62300,"columns":20,"freshness":"1h","status":"pass","tests_pass":3,"tests_fail":0,"tests_warn":0,"cost_day":0.06,"versions_avg":0,"upstream":["boohoo_products","boohoo_man_products","plt_products","nastygal_products","karen_millen_products","coast_products","debenhams_products"],"downstream":["fact_product_performance"]},
    "dim_time":               {"layer":"odl","domain":"conformed","entity":"dimension","brand":"All","rows":1096,"columns":11,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":[],"downstream":["fact_daily_sales"]},
    "dim_campaigns":          {"layer":"odl","domain":"marketing","entity":"dimension","brand":"All","rows":4200,"columns":27,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["rdl_meta_ads","rdl_google_ads","rdl_tiktok_ads"],"downstream":["fact_campaign_performance"]},
    "dim_marketing_channels": {"layer":"odl","domain":"marketing","entity":"dimension","brand":"All","rows":45,"columns":8,"freshness":"1h","status":"pass","tests_pass":1,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":[],"downstream":["fact_channel_performance"]},
    "fact_orders":            {"layer":"odl","domain":"conformed","entity":"fact","brand":"All","rows":445200,"columns":18,"freshness":"1h","status":"fail","tests_pass":3,"tests_fail":1,"tests_warn":0,"cost_day":0.15,"versions_avg":0,"upstream":["boohoo_orders","boohoo_man_orders","plt_orders","nastygal_orders","karen_millen_orders","coast_orders","debenhams_orders"],"downstream":["fact_daily_sales","fact_revenue_by_brand"]},
    "fact_meta_campaign_insights":  {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":89400,"columns":15,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.07,"versions_avg":0,"upstream":["rdl_meta_ads","dim_campaigns","dim_time"],"downstream":["fact_marketing_summary"]},
    "fact_google_ads_performance":  {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":67200,"columns":16,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.06,"versions_avg":0,"upstream":["rdl_google_ads","dim_campaigns","dim_time"],"downstream":["fact_marketing_summary"]},
    "fact_tiktok_ad_insights":      {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":45100,"columns":14,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.05,"versions_avg":0,"upstream":["rdl_tiktok_ads","dim_campaigns"],"downstream":["fact_marketing_summary"]},
    "fact_ga4_sessions":            {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":234100,"columns":12,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.10,"versions_avg":0,"upstream":["rdl_ga4_sessions","dim_time","dim_marketing_channels"],"downstream":["fact_funnel_metrics"]},
    "fact_email_engagement":        {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":12800,"columns":10,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["rdl_email_campaigns","dim_campaigns"],"downstream":["fact_email_performance"]},
    "fact_influencer_performance":  {"layer":"odl","domain":"marketing","entity":"fact","brand":"All","rows":3200,"columns":12,"freshness":"1h","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["rdl_influencer_posts","dim_campaigns"],"downstream":["fact_influencer_roi"]},
    "map_brand":              {"layer":"odl","domain":"mapping","entity":"map","brand":"All","rows":7,"columns":3,"freshness":"1h","status":"pass","tests_pass":1,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":[],"downstream":[]},
    "map_utm_sources":        {"layer":"odl","domain":"mapping","entity":"map","brand":"All","rows":25,"columns":4,"freshness":"1h","status":"pass","tests_pass":1,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":[],"downstream":[]},
    "map_channel_grouping":   {"layer":"odl","domain":"mapping","entity":"map","brand":"All","rows":12,"columns":3,"freshness":"1h","status":"pass","tests_pass":1,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":[],"downstream":[]},

    # ── ADL Layer ──
    "fact_marketing_summary":  {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":360,"columns":12,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_meta_campaign_insights","fact_google_ads_performance","fact_tiktok_ad_insights"],"downstream":[]},
    "fact_daily_sales":        {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":5460,"columns":12,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["fact_orders","dim_time"],"downstream":[]},
    "fact_revenue_by_brand":   {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":2520,"columns":11,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_orders","dim_products"],"downstream":[]},
    "fact_product_performance":{"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":8900,"columns":13,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["fact_orders","dim_products"],"downstream":[]},
    "fact_customer_segments":  {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":198750,"columns":11,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.08,"versions_avg":0,"upstream":["fact_orders","dim_customers"],"downstream":[]},
    "fact_funnel_metrics":     {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":900,"columns":8,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_ga4_sessions","fact_orders"],"downstream":[]},
    "fact_marketing_roas":     {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":720,"columns":10,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_marketing_summary","fact_orders"],"downstream":[]},
    "fact_channel_performance":{"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":450,"columns":9,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_meta_campaign_insights","fact_google_ads_performance","fact_tiktok_ad_insights","fact_ga4_sessions","fact_email_engagement","fact_influencer_performance"],"downstream":[]},
    "fact_campaign_performance":{"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":4200,"columns":11,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.03,"versions_avg":0,"upstream":["fact_meta_campaign_insights","fact_google_ads_performance","fact_tiktok_ad_insights"],"downstream":[]},
    "fact_marketing_spend_daily":{"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":3600,"columns":8,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.02,"versions_avg":0,"upstream":["fact_meta_campaign_insights","fact_google_ads_performance","fact_tiktok_ad_insights","fact_email_engagement","fact_influencer_performance"],"downstream":[]},
    "fact_email_performance":  {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":360,"columns":7,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":["fact_email_engagement"],"downstream":[]},
    "fact_influencer_roi":     {"layer":"adl","domain":"analytics","entity":"aggregate","brand":"All","rows":180,"columns":8,"freshness":"30m","status":"pass","tests_pass":2,"tests_fail":0,"tests_warn":0,"cost_day":0.01,"versions_avg":0,"upstream":["fact_influencer_performance"],"downstream":[]},
}


# ─── API Routes ───

@app.route("/")
def index():
    return send_from_directory("static", "index.html")


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


@app.route("/api/lineage")
def api_lineage():
    """Return nodes and edges for the lineage graph."""
    nodes = []
    edges = []
    for name, m in MODELS.items():
        nodes.append({"id": name, "layer": m["layer"], "status": m["status"], "entity": m["entity"], "rows": m["rows"], "domain": m["domain"]})
        for up in m["upstream"]:
            if up.startswith("source:"):
                src_id = up
                nodes.append({"id": src_id, "layer": "source", "status": "pass", "entity": "source", "rows": 0, "domain": ""})
                edges.append({"from": src_id, "to": name})
            elif up in MODELS:
                edges.append({"from": up, "to": name})
    # Deduplicate source nodes
    seen = set()
    unique_nodes = []
    for n in nodes:
        if n["id"] not in seen:
            unique_nodes.append(n)
            seen.add(n["id"])
    return jsonify({"nodes": unique_nodes, "edges": edges})


if __name__ == "__main__":
    print(f"Data Quality & Lineage Explorer -> http://localhost:{PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=True)
