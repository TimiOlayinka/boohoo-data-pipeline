"""
DAG 3: ODL (Operational Data Layer)
Runs dbt models tagged with 'odl' to build the star schema.
Models: dim_customers, dim_products, dim_time, fact_orders, map_brand
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.sensors.external_task import ExternalTaskSensor

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=3),
}

DBT_DIR = "/opt/airflow/dbt"

with DAG(
    dag_id="03_transform_odl",
    default_args=default_args,
    description="Operational Data Layer: Build star schema (dims, facts, maps)",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["transform", "dbt", "odl"],
) as dag:

    wait_for_rdl = ExternalTaskSensor(
        task_id="wait_for_rdl",
        external_dag_id="02_transform_rdl",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    dbt_run_odl = BashOperator(
        task_id="dbt_run_odl",
        bash_command=f"cd {DBT_DIR} && dbt run --select tag:odl --profiles-dir .",
    )

    dbt_test_odl = BashOperator(
        task_id="dbt_test_odl",
        bash_command=f"cd {DBT_DIR} && dbt test --select tag:odl --profiles-dir .",
    )

    wait_for_rdl >> dbt_run_odl >> dbt_test_odl
