"""Customer Experience mock data schema configurations."""

CX_SCHEMAS = {
    "tickets": {
        "filename": "tickets.jsonl.gz",
        "fields": ["ticket_id", "customer_id", "order_id", "status", "priority", "subject", "created_at", "updated_at", "agent_id", "team_id"]
    },
    "agents": {
        "filename": "agents.jsonl.gz",
        "fields": ["agent_id", "name", "email", "team_id", "status", "created_at"]
    },
    "teams": {
        "filename": "teams.jsonl.gz",
        "fields": ["team_id", "team_name", "tier", "specialty"]
    },
    "ticket_custom_fields": {
        "filename": "ticket_custom_fields.jsonl.gz",
        "fields": ["ticket_id", "field_name", "field_value"]
    },
    "ticket_interactions": {
        "filename": "ticket_interactions.jsonl.gz",
        "fields": ["interaction_id", "ticket_id", "agent_id", "customer_id", "channel", "message_length", "sentiment_score", "interaction_timestamp"]
    },
    "blnx_survey": {
        "filename": "blnx_survey.jsonl.gz",
        "fields": ["survey_id", "ticket_id", "customer_id", "agent_id", "csat_score", "resolution_score", "effort_score", "comments", "survey_date"]
    },
    "nps_visitview": {
        "filename": "nps_visitview.jsonl.gz",
        "fields": ["response_id", "customer_id", "order_id", "nps_score", "nps_category", "feedback_text", "device_type", "response_date"]
    }
}
