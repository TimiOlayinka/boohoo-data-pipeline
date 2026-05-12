"""
restructure_to_hnb.py
=====================
Restructures the hnb dbt project to the Holland & Barrett folder-per-model standard.

For each .sql model file, it:
1. Creates a folder with the model name
2. Moves the .sql file into it
3. Generates model.yml, README.md, runbook.md, tests.yml
4. Creates an empty derived/ subdirectory

Usage:
    python scripts/restructure_to_hnb.py
"""
import os
import re
import shutil
import glob
import yaml
from datetime import datetime

PROJECT_ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MODELS_ROOT = os.path.join(PROJECT_ROOT, 'models')

# ─────────────────────────────────────────────────────────────────
# Metadata extraction helpers
# ─────────────────────────────────────────────────────────────────

def extract_header_comment(sql: str) -> str:
    """Extract the header block comment (lines starting with --)."""
    lines = []
    for line in sql.split('\n'):
        s = line.strip()
        if s.startswith('--'):
            cleaned = s.lstrip('- ').strip()
            if cleaned:
                lines.append(cleaned)
        elif s.startswith('WITH') or s.startswith('SELECT'):
            break
    return '\n'.join(lines)


def extract_description(sql: str) -> str:
    """Extract the short description from the second -- comment line."""
    for line in sql.split('\n'):
        s = line.strip()
        if s.startswith('--') and not s.startswith('------'):
            cleaned = s.lstrip('- ').strip()
            # Skip the model name line (contains dots like rdl_marketing.meta_ads)
            if '.' in cleaned and ' ' not in cleaned.split('.')[0]:
                continue
            if cleaned and not cleaned.startswith('Pattern:') and not cleaned.startswith('Full-history'):
                return cleaned
    return ''


def extract_refs(sql: str) -> list:
    """Extract all ref() calls."""
    return re.findall(r"\{\{\s*ref\('(\w+)'\)\s*\}\}", sql)


def extract_sources(sql: str) -> list:
    """Extract all source() calls as (schema, table) tuples."""
    return re.findall(r"\{\{\s*source\('(\w+)',\s*'(\w+)'\)\s*\}\}", sql)


def extract_columns_from_final_select(sql: str) -> list:
    """Extract column names from the final SELECT block."""
    # Find the last SELECT ... FROM pattern
    matches = list(re.finditer(r'\bSELECT\b(.*?)\bFROM\b', sql, re.DOTALL | re.IGNORECASE))
    if not matches:
        return []
    
    select_body = matches[-1].group(1)
    columns = []
    for line in select_body.split('\n'):
        line = line.strip().rstrip(',')
        if not line or line.startswith('--') or line.startswith('*'):
            continue
        # Extract alias (after AS)
        as_match = re.search(r'\bAS\s+(\w+)\s*$', line, re.IGNORECASE)
        if as_match:
            columns.append(as_match.group(1))
        else:
            # Direct column name
            col = line.split('.')[-1].strip().split('::')[0].strip()
            if col and col not in ('*', ''):
                columns.append(col)
    return columns


def extract_partition_key(sql: str) -> list:
    """Extract PARTITION BY columns."""
    match = re.search(r'PARTITION BY\s+(.*?)\s+ORDER', sql, re.IGNORECASE | re.DOTALL)
    if match:
        keys = [k.strip() for k in match.group(1).split(',')]
        return keys
    return []


def infer_column_type(col_name: str, sql: str) -> str:
    """Infer column type from SQL casting or name patterns."""
    # Check for explicit cast in SQL
    escaped = re.escape(col_name)
    cast_match = re.search(rf'{escaped}\s*::\s*(\w+(?:\(\d+(?:,\d+)?\))?)', sql, re.IGNORECASE)
    if cast_match:
        return cast_match.group(1).lower()
    
    # Infer from naming patterns
    if col_name.endswith('_sk') or col_name == 'record_hash':
        return 'varchar(200)'
    elif col_name.endswith('_nk') or col_name.endswith('_id') or col_name == 'order_id':
        return 'varchar(100)'
    elif col_name.endswith('_date') or col_name == 'date_nk' or col_name == 'ingest_date':
        return 'date'
    elif col_name.endswith('_ts') or col_name.endswith('_timestamp') or col_name == 'ingest_ts':
        return 'timestamp'
    elif col_name.startswith('is_') or col_name == 'is_latest':
        return 'boolean'
    elif col_name in ('row_version', 'version_count', 'item_count', 'impressions', 'clicks',
                       'reach', 'likes', 'comments', 'shares', 'saves', 'conversions',
                       'link_clicks', 'purchase', 'total_engagement', 'year', 'month',
                       'day_of_week', 'day_of_month', 'quarter', 'month_number'):
        return 'integer'
    elif col_name in ('spend', 'revenue', 'cost', 'total_amount', 'discount_amount',
                       'shipping_cost', 'current_price', 'cost_price', 'rrp', 'margin',
                       'cpc', 'cpm', 'ctr', 'roas', 'roi', 'emv', 'revenue_attributed',
                       'gross_revenue', 'net_revenue'):
        return 'numeric(18,2)'
    elif col_name.endswith('_pct') or col_name.endswith('_rate'):
        return 'numeric(8,2)'
    else:
        return 'varchar'


def detect_layer(filepath: str) -> str:
    """Detect the layer (rdl/odl/adl) from the file path."""
    parts = filepath.replace('\\', '/').lower()
    if '/rdl/' in parts:
        return 'rdl'
    elif '/odl/' in parts:
        return 'odl'
    elif '/adl/' in parts:
        return 'adl'
    return 'unknown'


def detect_domain(filepath: str) -> str:
    """Detect the domain from the file path."""
    parts = filepath.replace('\\', '/').split('/')
    for i, p in enumerate(parts):
        if p in ('rdl', 'odl', 'adl') and i + 1 < len(parts):
            return parts[i + 1]
    return 'general'


def detect_model_type(model_name: str) -> str:
    """Detect model type (dim/fact/map/rdl) from the name."""
    if model_name.startswith('dim_'):
        return 'dim'
    elif model_name.startswith('fact_'):
        return 'fact'
    elif model_name.startswith('map_'):
        return 'map'
    elif model_name.startswith('rdl_'):
        return 'rdl'
    else:
        return 'rdl'


def detect_schema(filepath: str, layer: str) -> str:
    """Detect the target schema from the path."""
    domain = detect_domain(filepath)
    if layer == 'rdl':
        return f'rdl_{domain}'
    elif layer == 'odl':
        return 'odl'
    elif layer == 'adl':
        return 'bi'
    return domain


def detect_brand(sql: str) -> str:
    """Extract brand from SQL."""
    match = re.search(r"'(\w[\w\s]*?)'\s+AS\s+brand", sql)
    return match.group(1) if match else 'All'


def detect_criticality(layer: str, model_type: str) -> str:
    """Infer criticality from layer and type."""
    if layer == 'adl':
        return 'high'
    elif layer == 'odl' and model_type in ('fact', 'dim'):
        return 'high'
    elif layer == 'rdl':
        return 'medium'
    return 'medium'


# ─────────────────────────────────────────────────────────────────
# Template generators
# ─────────────────────────────────────────────────────────────────

def generate_model_yml(model_name: str, meta: dict) -> str:
    """Generate model.yml content."""
    data = {
        'model': {
            'name': model_name,
            'domain': meta['domain'],
            'schema': meta['schema'],
            'layer': meta['layer'],
        },
        'owners': {
            'workstream': 'hnb-data-engineering',
            'analytics_owner': 'data-team@hnb.com',
            'business_owner': f"{meta['domain']}-team@hnb.com",
            'technical_owner': 'data-team@hnb.com',
        },
        'service': {
            'sla': 'Daily by 07:00 Europe/London',
            'refresh_cadence': 'daily',
            'criticality': meta['criticality'],
        },
        'description': {
            'short': meta['description'],
            'business_purpose': meta['description'],
        },
        'grain': meta['grain'],
        'depends_on_products': meta['refs'] if meta['refs'] else meta['source_tables'],
        'documentation': {
            'main': './README.md',
            'runbook': './runbook.md',
        },
        'classification': {
            'certified_for_reporting': meta['layer'] in ('odl', 'adl'),
            'contains_pii': 'customer' in model_name or 'email' in model_name,
            'confidentiality': 'internal',
        },
        'tags': meta['tags'],
    }
    return yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True)


def generate_readme(model_name: str, meta: dict) -> str:
    """Generate README.md content."""
    # Build table structure
    table_rows = []
    for col in meta['columns']:
        col_type = infer_column_type(col, meta['sql'])
        desc = _describe_column(col, meta)
        table_rows.append(f'| {col} | {col_type} | {desc} |')
    table_str = '\n'.join(table_rows) if table_rows else '| (see SQL) | | |'

    # Build upstream list
    upstream = []
    for schema, table in meta['sources']:
        upstream.append(f"- `source('{schema}', '{table}')`")
    for ref in meta['refs']:
        upstream.append(f"- `ref('{ref}')`")
    upstream_str = '\n'.join(upstream) if upstream else '- None'

    # Build business rules
    rules = _extract_business_rules(meta)
    rules_str = '\n'.join(f'- {r}' for r in rules) if rules else '- Standard pass-through'

    # Build downstream
    downstream = meta.get('downstream', [])
    downstream_str = '\n'.join(f'- `{d}`' for d in downstream) if downstream else '- See lineage map'

    return f"""# {model_name}

## Purpose
{meta['description']}

## Grain
{meta['grain']}

## Table structure
| Column | Type | Description |
|--------|------|-------------|
{table_str}

## Key business rules
{rules_str}

## Upstream inputs
{upstream_str}

## Downstream usage
{downstream_str}

## SLA
Daily by 07:00 Europe/London

## Criticality
{meta['criticality'].capitalize()}
"""


def generate_runbook(model_name: str, meta: dict) -> str:
    """Generate runbook.md content."""
    # Infer failure modes from layer
    if meta['layer'] == 'rdl':
        failure_modes = """- Source data not delivered to S3 on time
- Schema drift in source system (new/renamed/removed columns)
- Null values in natural key columns ({keys})
- Ingestion timestamp parsing failure (ISO format change)""".format(keys=', '.join(meta['partition_keys']))
        diagnostics = """```sql
-- Check latest ingestion date
SELECT MAX(ingest_date), COUNT(*) FROM {{{{ ref('{name}') }}}}
WHERE is_latest;

-- Check for null natural keys
SELECT COUNT(*) FROM {{{{ ref('{name}') }}}}
WHERE {key_check};

-- Check version distribution
SELECT version_count, COUNT(*) 
FROM {{{{ ref('{name}') }}}}
GROUP BY 1 ORDER BY 1 DESC LIMIT 10;
```""".format(
            name=model_name,
            key_check=' OR '.join(f'{k} IS NULL' for k in meta['partition_keys']) if meta['partition_keys'] else 'FALSE'
        )
    elif meta['layer'] == 'odl':
        failure_modes = """- Upstream RDL model failed or returned empty
- Join key mismatch between fact and dimension
- Surrogate key collision (MD5 hash collision — extremely rare)
- is_latest filter returns no rows (ingestion issue)"""
        diagnostics = """```sql
-- Check row count vs yesterday
SELECT COUNT(*) FROM {{{{ ref('{name}') }}}};

-- Check for orphan keys (fact without dimension)
-- Adapt the JOIN below for this specific model
SELECT COUNT(*) FROM {{{{ ref('{name}') }}}} f
WHERE f.brand IS NULL;
```""".format(name=model_name)
    else:
        failure_modes = """- Upstream ODL model failed
- Aggregation produces unexpected nulls
- Month-over-month calculation returns null for first month"""
        diagnostics = """```sql
-- Check date coverage
SELECT MIN(date_nk), MAX(date_nk), COUNT(DISTINCT date_nk)
FROM {{{{ ref('{name}') }}}};
```""".format(name=model_name)

    return f"""# Runbook: {model_name}

## What this model supports
{meta['description']}

## Expected refresh
Daily, triggered by Airflow DAG `hnb_dbt_run`

## Failure impact
{'Downstream ODL and ADL models will have stale data. Dashboards may show outdated metrics.' if meta['layer'] == 'rdl' else 'Dashboard metrics will be stale or incorrect. Executive reports may show wrong KPIs.' if meta['layer'] == 'adl' else 'Downstream ADL aggregates and dashboards will be affected.'}

## Common failure modes
{failure_modes}

## Diagnostics
{diagnostics}

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select {model_name}`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select {model_name}+`

## Escalation
data-team@hnb.com

## Related checks
- dbt test: `dbt test --select {model_name}`
- Freshness: `dbt source freshness`
"""


def generate_tests_yml(model_name: str, meta: dict) -> str:
    """Generate tests.yml content."""
    tests = {'duplicate_tests': [], 'gap_tests': []}

    # Duplicate test based on partition key
    if meta['partition_keys']:
        key_fields = meta['partition_keys']
        if meta['layer'] == 'rdl':
            # For RDL, uniqueness is per natural key + ingest_date (since we keep all versions)
            tests['duplicate_tests'].append({
                'name': f"no_duplicate_{key_fields[0]}",
                'description': f"Each ({', '.join(key_fields)}, ingest_date) combination should be unique",
                'enabled': True,
                'schedule': 'daily',
                'field': key_fields + ['ingest_date'],
                'severity': 'error',
            })
        else:
            tests['duplicate_tests'].append({
                'name': f"no_duplicate_{key_fields[0]}",
                'description': f"Each ({', '.join(key_fields)}) should be unique after dedup",
                'enabled': True,
                'schedule': 'daily',
                'field': key_fields,
                'severity': 'error',
            })

    # Surrogate key uniqueness for ODL
    sk_cols = [c for c in meta['columns'] if c.endswith('_sk')]
    for sk in sk_cols:
        tests['duplicate_tests'].append({
            'name': f"unique_{sk}",
            'description': f"Surrogate key {sk} must be unique",
            'enabled': True,
            'schedule': 'daily',
            'field': [sk],
            'severity': 'error',
        })

    # Date gap test
    date_cols = [c for c in meta['columns'] if c in ('date_nk', 'ingest_date', 'order_date')]
    if date_cols:
        tests['gap_tests'].append({
            'name': f"no_missing_{date_cols[0]}",
            'description': f"No gaps in {date_cols[0]} coverage",
            'enabled': True,
            'schedule': 'daily',
            'field': [date_cols[0]],
            'severity': 'warning',
        })

    return yaml.dump(tests, default_flow_style=False, sort_keys=False)


# ─────────────────────────────────────────────────────────────────
# Column description helper
# ─────────────────────────────────────────────────────────────────

COLUMN_DESCRIPTIONS = {
    'customer_sk': 'Surrogate key: MD5(customer_id || brand)',
    'customer_nk': 'Natural key from source system',
    'order_sk': 'Surrogate key: MD5(order_id || brand)',
    'order_nk': 'Natural key from source system',
    'product_sk': 'Surrogate key: MD5(product_id || brand)',
    'product_nk': 'Natural key from source system',
    'date_nk': 'Canonical date key (standardised from source date column)',
    'brand': 'HNB Group brand name',
    'brand_tier': 'Brand tier: Value, Mid, or Premium',
    'source_system': 'Source platform identifier',
    'ingest_date': 'Date this version was loaded from source',
    'ingest_ts': 'Precise ingestion timestamp',
    'row_version': '1 = latest version, 2 = previous, etc.',
    'is_latest': 'TRUE for the most recent version of this record',
    'version_count': 'Total number of versions for this record',
    'record_hash': 'MD5 hash of all business columns for change detection',
    'dwh_created_at': 'Timestamp when this row was created in the warehouse',
    'year': 'Year extracted from date',
    'month': 'Month extracted from date',
    'day_of_week': 'Day of week (0=Sunday)',
    'gross_revenue': 'Total amount + shipping cost',
    'net_revenue': 'Total amount - discount',
    'discount_pct': 'Discount as percentage of RRP',
    'margin': 'Price minus cost',
    'margin_pct': 'Margin as percentage of price',
}


def _describe_column(col: str, meta: dict) -> str:
    """Generate a human-readable description for a column."""
    if col in COLUMN_DESCRIPTIONS:
        return COLUMN_DESCRIPTIONS[col]
    
    # Infer from name
    if col.endswith('_id'):
        return f'{col.replace("_id", "").replace("_", " ").title()} identifier'
    elif col.endswith('_name'):
        return f'{col.replace("_name", "").replace("_", " ").title()} name'
    elif col.endswith('_status'):
        return f'{col.replace("_status", "").replace("_", " ").title()} status'
    elif col.endswith('_date'):
        return f'{col.replace("_date", "").replace("_", " ").title()} date'
    elif col.startswith('is_'):
        return f'Boolean: {col.replace("is_", "").replace("_", " ")}'
    
    return col.replace('_', ' ').capitalize()


def _extract_business_rules(meta: dict) -> list:
    """Extract business rules from SQL patterns."""
    rules = []
    sql = meta['sql']
    
    if 'ROW_NUMBER()' in sql:
        keys = ', '.join(meta['partition_keys']) if meta['partition_keys'] else 'natural key'
        if meta['layer'] == 'rdl':
            rules.append(f'Row versioning by ({keys}), ordered by ingest_date DESC, ingest_ts DESC')
            rules.append('ALL historical versions retained — no dedup filter applied')
        else:
            rules.append(f'Deduplicated by ({keys}), keeping latest version')
    
    if 'UNION ALL' in sql:
        ref_count = len(meta['refs'])
        rules.append(f'Unifies {ref_count} brand-level models via UNION ALL')
    
    if 'MD5(' in sql:
        rules.append('Surrogate keys generated via MD5(natural_key || \'|\' || brand)')
    
    if 'CASE WHEN' in sql or 'CASE\n' in sql:
        rules.append('Contains CASE WHEN classification logic (see SQL for detail)')
    
    if 'record_hash' in sql:
        rules.append('Record hash (MD5 of business columns) for change detection')
    
    if 'is_latest' in sql and meta['layer'] != 'rdl':
        rules.append('Filters to is_latest = TRUE from RDL (current-state only)')
    
    if 'LEFT JOIN' in sql:
        joins = re.findall(r"LEFT JOIN\s+\{\{\s*ref\('(\w+)'\)", sql)
        for j in joins:
            rules.append(f'LEFT JOIN to {j} for enrichment')
    
    return rules


# ─────────────────────────────────────────────────────────────────
# Main restructuring logic
# ─────────────────────────────────────────────────────────────────

def process_model(sql_path: str):
    """Process a single SQL model file — create folder + companion files."""
    model_name = os.path.splitext(os.path.basename(sql_path))[0]
    parent_dir = os.path.dirname(sql_path)
    model_dir = os.path.join(parent_dir, model_name)
    
    # Skip if already restructured (folder exists with SQL inside)
    target_sql = os.path.join(model_dir, f'{model_name}.sql')
    if os.path.exists(target_sql):
        print(f'  SKIP (already done): {model_name}')
        return
    
    # Read SQL
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    # Extract metadata
    layer = detect_layer(sql_path)
    domain = detect_domain(sql_path)
    schema = detect_schema(sql_path, layer)
    columns = extract_columns_from_final_select(sql)
    refs = extract_refs(sql)
    sources = extract_sources(sql)
    partition_keys = extract_partition_key(sql)
    description = extract_description(sql)
    brand = detect_brand(sql)
    criticality = detect_criticality(layer, detect_model_type(model_name))
    
    if not description:
        description = f'{model_name.replace("_", " ").title()} — {layer.upper()} layer model'
    
    # Infer grain
    if partition_keys:
        grain = f"One row per ({', '.join(partition_keys)})"
        if layer == 'rdl':
            grain += ' per ingestion version'
        elif 'brand' not in partition_keys:
            grain += ' per brand'
    else:
        grain = f'One row per record in {model_name}'
    
    # Build tags
    tags = [layer, domain]
    if brand != 'All':
        tags.append(brand.lower().replace(' ', '_'))
    if 'marketing' in domain or 'marketing' in model_name:
        tags.append('marketing')
    if 'order' in model_name:
        tags.append('commerce')
    
    meta = {
        'sql': sql,
        'layer': layer,
        'domain': domain,
        'schema': schema,
        'columns': columns,
        'refs': refs,
        'sources': sources,
        'source_tables': [f'{s}.{t}' for s, t in sources],
        'partition_keys': partition_keys,
        'description': description,
        'brand': brand,
        'criticality': criticality,
        'grain': grain,
        'tags': tags,
    }
    
    # Create folder structure
    os.makedirs(model_dir, exist_ok=True)
    os.makedirs(os.path.join(model_dir, 'derived'), exist_ok=True)
    
    # Move SQL file
    shutil.move(sql_path, target_sql)
    
    # Generate companion files
    with open(os.path.join(model_dir, 'model.yml'), 'w', encoding='utf-8') as f:
        f.write(generate_model_yml(model_name, meta))
    
    with open(os.path.join(model_dir, 'README.md'), 'w', encoding='utf-8') as f:
        f.write(generate_readme(model_name, meta))
    
    with open(os.path.join(model_dir, 'runbook.md'), 'w', encoding='utf-8') as f:
        f.write(generate_runbook(model_name, meta))
    
    with open(os.path.join(model_dir, 'tests.yml'), 'w', encoding='utf-8') as f:
        f.write(generate_tests_yml(model_name, meta))
    
    print(f'  DONE: {model_name}/ ({len(columns)} columns, {len(refs)} refs, {len(sources)} sources)')


def main():
    print(f'Restructuring dbt models to HnB standard')
    print(f'Models root: {MODELS_ROOT}\n')
    
    # Find all SQL files (exclude _sources.yml, _schema.yml, etc.)
    sql_files = sorted(glob.glob(os.path.join(MODELS_ROOT, '**', '*.sql'), recursive=True))
    
    # Filter out files already inside a model folder (avoid double-processing)
    top_level_sqls = []
    for f in sql_files:
        model_name = os.path.splitext(os.path.basename(f))[0]
        parent = os.path.basename(os.path.dirname(f))
        if parent != model_name:  # Not already in a model folder
            top_level_sqls.append(f)
    
    print(f'Found {len(top_level_sqls)} models to restructure\n')
    
    for layer_name in ['rdl', 'odl', 'adl']:
        layer_files = [f for f in top_level_sqls if f'/{layer_name}/' in f.replace('\\', '/') or f'\\{layer_name}\\' in f]
        if layer_files:
            print(f'--- {layer_name.upper()} Layer ({len(layer_files)} models) ---')
            for f in sorted(layer_files):
                process_model(f)
            print()
    
    print(f'Restructuring complete.')
    
    # Summary
    all_folders = glob.glob(os.path.join(MODELS_ROOT, '**', 'model.yml'), recursive=True)
    print(f'Total model folders created: {len(all_folders)}')


if __name__ == '__main__':
    main()
