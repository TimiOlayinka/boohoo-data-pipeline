"""
05_export_parquet.py
====================
Airflow DAG: Reads export_jobs.yml and submits UNLOAD SQL to Redshift.
No business logic in Python — all config lives in YAML, all queries in SQL.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import boto3
import yaml
import os
import time

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "..", "config", "export_jobs.yml")
SQL_PATH = os.path.join(os.path.dirname(__file__), "..", "sql", "unload_to_parquet.sql")

default_args = {
    "owner": "data-team",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


def load_config():
    """Load YAML config, resolve env vars."""
    with open(CONFIG_PATH) as f:
        raw = f.read()
    for key, val in os.environ.items():
        raw = raw.replace(f"${{{key}}}", val)
    return yaml.safe_load(raw)


def load_sql_template():
    """Load the UNLOAD SQL template."""
    with open(SQL_PATH) as f:
        return f.read()


def submit_unload(schema, table, filter_clause, layer, ds, **kwargs):
    """Submit a single UNLOAD statement to Redshift Data API."""
    config = load_config()
    sql_template = load_sql_template()
    settings = config["settings"]

    s3_path = f"s3://{settings['s3_bucket']}/{layer}/{table}/{ds}/"

    sql = sql_template.format(
        schema=schema,
        table=table,
        filter=filter_clause or "",
        s3_path=s3_path,
        iam_role=settings["iam_role"],
    )

    client = boto3.client("redshift-data", region_name=settings["region"])
    response = client.execute_statement(
        WorkgroupName=settings["workgroup"],
        Database=settings["database"],
        Sql=sql,
    )

    # Poll until done
    stmt_id = response["Id"]
    while True:
        status = client.describe_statement(Id=stmt_id)
        state = status["Status"]
        if state == "FINISHED":
            break
        elif state in ("FAILED", "ABORTED"):
            raise Exception(f"UNLOAD failed for {schema}.{table}: {status.get('Error')}")
        time.sleep(2)


# ─── Build DAG from YAML ───

with DAG(
    dag_id="05_export_parquet",
    description="UNLOAD Redshift tables to S3 Parquet (config-driven)",
    default_args=default_args,
    schedule_interval="10 2 * * 1,3,5",  # 02:10 UTC Mon/Wed/Fri (after dbt)
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["export", "parquet", "duckdb"],
) as dag:

    config = load_config()

    for layer, layer_cfg in config["exports"].items():
        for group in layer_cfg["models"]:
            schema = group["schema"]
            filter_clause = group.get("filter", "")
            for table in group["tables"]:
                PythonOperator(
                    task_id=f"unload_{layer}_{table}",
                    python_callable=submit_unload,
                    op_kwargs={
                        "schema": schema,
                        "table": table,
                        "filter_clause": filter_clause,
                        "layer": layer,
                    },
                    provide_context=True,
                )
