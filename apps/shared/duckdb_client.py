"""
duckdb_client.py
================
Shared DuckDB client for all dashboard apps.
Reads Parquet files from S3 (or local cache) and provides
a clean query interface for the BI dashboards.
"""
import duckdb
import os

S3_BUCKET = os.environ.get("PARQUET_BUCKET", "boohoo-data-quality-staging")
S3_REGION = os.environ.get("AWS_REGION", "eu-west-2")
LOCAL_CACHE = os.environ.get("PARQUET_CACHE", os.path.join(os.path.dirname(__file__), "..", ".cache"))


class DuckDBClient:
    """DuckDB client that reads Parquet from S3 or local cache."""

    def __init__(self, use_s3: bool = False):
        self.conn = duckdb.connect(":memory:")
        self.use_s3 = use_s3

        if use_s3:
            self.conn.execute("INSTALL httpfs; LOAD httpfs;")
            self.conn.execute(f"SET s3_region = '{S3_REGION}';")

    def _parquet_path(self, layer: str, model: str, date: str = "latest") -> str:
        """Build path to Parquet file."""
        if self.use_s3:
            if date == "latest":
                return f"s3://{S3_BUCKET}/{layer}/{model}/*/*.parquet"
            return f"s3://{S3_BUCKET}/{layer}/{model}/{date}/*.parquet"
        else:
            base = os.path.join(LOCAL_CACHE, layer, model)
            if date == "latest":
                # Find the most recent date folder
                if os.path.exists(base):
                    dates = sorted(os.listdir(base), reverse=True)
                    if dates:
                        return os.path.join(base, dates[0], "*.parquet")
            return os.path.join(base, date, "*.parquet")

    def query(self, sql: str) -> list[dict]:
        """Execute SQL and return results as list of dicts."""
        result = self.conn.execute(sql)
        columns = [desc[0] for desc in result.description]
        rows = result.fetchall()
        return [dict(zip(columns, row)) for row in rows]

    def register_model(self, layer: str, model: str, date: str = "latest"):
        """Register a Parquet file as a DuckDB table."""
        path = self._parquet_path(layer, model, date)
        self.conn.execute(f"CREATE OR REPLACE VIEW {model} AS SELECT * FROM read_parquet('{path}')")

    def register_layer(self, layer: str, models: list[str], date: str = "latest"):
        """Register all models for a layer."""
        for model in models:
            self.register_model(layer, model, date)

    def get_row_count(self, model: str) -> int:
        """Get row count for a registered model."""
        result = self.conn.execute(f"SELECT COUNT(*) FROM {model}").fetchone()
        return result[0] if result else 0

    def get_columns(self, model: str) -> list[dict]:
        """Get column info for a registered model."""
        result = self.conn.execute(f"DESCRIBE {model}")
        columns = [desc[0] for desc in result.description]
        rows = result.fetchall()
        return [dict(zip(columns, row)) for row in rows]

    def close(self):
        """Close the DuckDB connection."""
        self.conn.close()
