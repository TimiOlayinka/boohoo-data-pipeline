"""
DAG 1.5: S3 → Redshift Loader (YAML-Driven)
Reads copy_jobs.yml to dynamically generate COPY tasks.
To add a new brand or dataset, edit config/copy_jobs.yml — no Python changes needed.
"""
import os
import yaml
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.utils.task_group import TaskGroup
import boto3

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

# ── Load YAML Config ──
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "..", "config", "copy_jobs.yml")
with open(CONFIG_PATH, "r") as f:
    config = yaml.safe_load(f)

SETTINGS = config["settings"]


def copy_s3_to_redshift(brand, source, dataset, schema, table, **kwargs):
    """Execute Redshift COPY command to load JSONL.GZ from S3."""
    execution_date = kwargs["ds"]
    s3_path = f"s3://{SETTINGS['bucket']}/{brand}/{source}/{dataset}/history/ingest_date={execution_date}/"

    sql = f"""
        COPY "{schema}"."{table}"
        FROM '{s3_path}'
        IAM_ROLE '{SETTINGS["iam_role"]}'
        FORMAT AS JSON 'auto'
        GZIP
        TIMEFORMAT 'auto'
        DATEFORMAT 'auto'
        TRUNCATECOLUMNS
        ACCEPTINVCHARS
        REGION '{SETTINGS["region"]}';
    """

    client = boto3.client("redshift-data", region_name=SETTINGS["region"])
    response = client.execute_statement(
        WorkgroupName=SETTINGS["workgroup"],
        Database=SETTINGS["database"],
        Sql=sql,
    )
    print(f"✅ COPY {schema}.{table} ← {s3_path}")
    print(f"   Statement ID: {response['Id']}")


def _build_table_name(source_cfg, brand, dataset):
    """Build the Redshift table name from config. Uses prefix if defined."""
    prefix = source_cfg.get("prefix", brand)
    return f"{prefix}_{dataset}_history"


with DAG(
    dag_id="01b_s3_to_redshift",
    default_args=default_args,
    description="YAML-driven S3 → Redshift loader with TaskGroups per source system",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["ingestion", "redshift", "copy"],
) as dag:

    wait_for_ingestion = ExternalTaskSensor(
        task_id="wait_for_ingestion",
        external_dag_id="01_ingestion",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    all_groups = []

    for source_name, source_cfg in config["sources"].items():
        schema = source_cfg["schema"]

        with TaskGroup(source_name) as source_group:
            for brand, brand_cfg in source_cfg["brands"].items():
                for dataset in brand_cfg["datasets"]:
                    table = _build_table_name(source_cfg, brand, dataset)

                    PythonOperator(
                        task_id=f"copy_{brand}_{dataset}",
                        python_callable=copy_s3_to_redshift,
                        op_kwargs={
                            "brand": brand,
                            "source": source_name,
                            "dataset": dataset,
                            "schema": schema,
                            "table": table,
                        },
                    )

        all_groups.append(source_group)

    wait_for_ingestion >> all_groups
