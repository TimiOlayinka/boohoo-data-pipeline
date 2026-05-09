"""
Redshift Loader Lambda — Loads CSV from S3 into Redshift Serverless.

Triggered by S3 ObjectCreated events on the raw-data/ prefix.
Uses the Redshift Data API to execute COPY commands.

Flow:
  1. Parse S3 event to extract bucket/key
  2. Determine target table from the S3 key path
  3. Execute CREATE TABLE IF NOT EXISTS (idempotent)
  4. Execute COPY command to load the CSV
  5. Log results

Environment Variables:
  WORKGROUP_NAME   — Redshift Serverless workgroup name
  DATABASE_NAME    — Target database name
  REDSHIFT_ROLE_ARN — IAM role ARN for Redshift to access S3
"""

import os
import json
import time
from typing import Any

import boto3

redshift_data = boto3.client("redshift-data")

WORKGROUP_NAME = os.environ["WORKGROUP_NAME"]
DATABASE_NAME = os.environ["DATABASE_NAME"]
REDSHIFT_ROLE_ARN = os.environ["REDSHIFT_ROLE_ARN"]


# ---------------------------------------------------------------------------
# Table definitions — DDL for each table
# ---------------------------------------------------------------------------

TABLE_DDL: dict[str, str] = {
    "dim_customers": """
        CREATE TABLE IF NOT EXISTS dim_customers (
            customer_id     VARCHAR(20)   NOT NULL,
            first_name      VARCHAR(50)   NOT NULL,
            last_name       VARCHAR(50)   NOT NULL,
            email           VARCHAR(100)  NOT NULL,
            city            VARCHAR(50)   NOT NULL,
            country         VARCHAR(50)   NOT NULL,
            segment         VARCHAR(20)   NOT NULL,
            signup_date     DATE          NOT NULL,
            PRIMARY KEY (customer_id)
        )
        DISTSTYLE ALL
        SORTKEY (signup_date);
    """,
    "dim_products": """
        CREATE TABLE IF NOT EXISTS dim_products (
            product_id      VARCHAR(20)     NOT NULL,
            product_name    VARCHAR(100)    NOT NULL,
            category        VARCHAR(50)     NOT NULL,
            subcategory     VARCHAR(50)     NOT NULL,
            unit_price      DECIMAL(10,2)   NOT NULL,
            cost_price      DECIMAL(10,2)   NOT NULL,
            is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
            PRIMARY KEY (product_id)
        )
        DISTSTYLE ALL
        SORTKEY (category, subcategory);
    """,
    "fact_orders": """
        CREATE TABLE IF NOT EXISTS fact_orders (
            order_id        VARCHAR(20)     NOT NULL,
            customer_id     VARCHAR(20)     NOT NULL,
            order_date      DATE            NOT NULL,
            order_time      VARCHAR(8)      NOT NULL,
            status          VARCHAR(20)     NOT NULL,
            total_amount    DECIMAL(12,2)   NOT NULL,
            discount_amount DECIMAL(12,2)   NOT NULL DEFAULT 0,
            shipping_cost   DECIMAL(10,2)   NOT NULL DEFAULT 0,
            PRIMARY KEY (order_id)
        )
        DISTSTYLE KEY
        DISTKEY (customer_id)
        SORTKEY (order_date);
    """,
    "fact_order_items": """
        CREATE TABLE IF NOT EXISTS fact_order_items (
            order_item_id   VARCHAR(20)     NOT NULL,
            order_id        VARCHAR(20)     NOT NULL,
            product_id      VARCHAR(20)     NOT NULL,
            quantity        INTEGER         NOT NULL,
            unit_price      DECIMAL(10,2)   NOT NULL,
            discount_pct    INTEGER         NOT NULL DEFAULT 0,
            line_total      DECIMAL(12,2)   NOT NULL,
            PRIMARY KEY (order_item_id)
        )
        DISTSTYLE KEY
        DISTKEY (order_id)
        SORTKEY (order_id);
    """,
}


def _execute_sql(sql: str, description: str) -> str:
    """Execute a SQL statement via the Redshift Data API and wait for completion."""
    print(f"Executing: {description}")
    print(f"SQL: {sql[:200]}...")

    response = redshift_data.execute_statement(
        WorkgroupName=WORKGROUP_NAME,
        Database=DATABASE_NAME,
        Sql=sql,
    )

    statement_id = response["Id"]
    print(f"Statement ID: {statement_id}")

    # Poll for completion (Data API is async)
    max_wait = 120  # seconds
    elapsed = 0
    while elapsed < max_wait:
        status_response = redshift_data.describe_statement(Id=statement_id)
        status = status_response["Status"]

        if status == "FINISHED":
            print(f"✓ {description} — completed successfully")
            if "ResultRows" in status_response:
                print(f"  Rows affected: {status_response['ResultRows']}")
            return statement_id

        if status == "FAILED":
            error = status_response.get("Error", "Unknown error")
            print(f"✗ {description} — FAILED: {error}")
            raise RuntimeError(f"SQL execution failed: {error}")

        if status == "ABORTED":
            raise RuntimeError(f"SQL execution was aborted: {description}")

        # Wait and retry
        time.sleep(2)
        elapsed += 2

    raise TimeoutError(f"SQL execution timed out after {max_wait}s: {description}")


def _extract_table_name(s3_key: str) -> str | None:
    """
    Extract the table name from the S3 key.

    Expected key format: raw-data/{table_name}/{table_name}_{timestamp}.csv
    Example: raw-data/dim_customers/dim_customers_20250509_140000.csv
    """
    parts = s3_key.split("/")
    # Find the table name segment after "raw-data"
    for i, part in enumerate(parts):
        if part == "raw-data" and i + 1 < len(parts):
            table_name = parts[i + 1]
            if table_name in TABLE_DDL:
                return table_name

    return None


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Main entry point — triggered by S3 ObjectCreated events.

    For each uploaded CSV file:
      1. Determine the target table
      2. Create the table if it doesn't exist
      3. TRUNCATE existing data (full refresh strategy)
      4. COPY the new data from S3
    """
    results = []

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        print(f"Processing: s3://{bucket}/{key}")

        # Determine target table
        table_name = _extract_table_name(key)
        if not table_name:
            print(f"⚠ Could not determine table from key: {key} — skipping")
            continue

        print(f"Target table: {table_name}")

        try:
            # Step 1: Create table if not exists
            _execute_sql(
                TABLE_DDL[table_name],
                f"CREATE TABLE {table_name}",
            )

            # Step 2: Truncate existing data (full refresh)
            _execute_sql(
                f"TRUNCATE TABLE {table_name};",
                f"TRUNCATE {table_name}",
            )

            # Step 3: COPY data from S3
            copy_sql = f"""
                COPY {table_name}
                FROM 's3://{bucket}/{key}'
                IAM_ROLE '{REDSHIFT_ROLE_ARN}'
                FORMAT AS CSV
                IGNOREHEADER 1
                DATEFORMAT 'auto'
                TIMEFORMAT 'auto'
                REGION '{os.environ.get("AWS_REGION", "eu-west-2")}';
            """

            _execute_sql(copy_sql, f"COPY {table_name}")

            results.append({
                "table": table_name,
                "source": f"s3://{bucket}/{key}",
                "status": "success",
            })

        except Exception as e:
            print(f"✗ Error processing {table_name}: {e}")
            results.append({
                "table": table_name,
                "source": f"s3://{bucket}/{key}",
                "status": "error",
                "error": str(e),
            })

    response = {
        "status": "complete",
        "tables_processed": len(results),
        "results": results,
    }

    print(f"Loader complete: {json.dumps(response, indent=2)}")
    return response
