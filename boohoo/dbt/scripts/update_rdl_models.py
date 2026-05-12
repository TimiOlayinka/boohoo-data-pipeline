"""
Batch-update all RDL models to the full-history pattern.
Replaces `dedup WHERE rnk = 1` with `versioned` CTE keeping ALL rows,
adding row_version, is_latest, version_count, record_hash columns.
"""
import os, re, glob

RDL_ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'models', 'rdl'))

def transform(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    # Skip already transformed
    if 'is_latest' in sql:
        print(f"  SKIP: {os.path.basename(filepath)}")
        return
    if 'WHERE rnk = 1' not in sql:
        print(f"  SKIP (no dedup): {os.path.basename(filepath)}")
        return

    # Extract model name from header
    name_match = re.search(r'^-- (rdl_\w+\.\w+|rdl_marketing\.\w+)', sql, re.MULTILINE)
    model_name = name_match.group(1) if name_match else os.path.basename(filepath).replace('.sql','')

    # Extract PARTITION BY key
    part_match = re.search(r'PARTITION BY (.*?) ORDER', sql, re.DOTALL)
    partition_key = part_match.group(1).strip() if part_match else 'id'

    # Extract history CTE columns (between SELECT and FROM in the WITH history block)
    hist_match = re.search(r'WITH history AS \(\s*SELECT\s+(.*?)\s+FROM', sql, re.DOTALL)
    hist_body = hist_match.group(1) if hist_match else ''
    
    # Parse column aliases from history CTE
    biz_cols = []
    for line in hist_body.split('\n'):
        line = line.strip().rstrip(',')
        if not line or line.startswith('--') or 'ingest_date' in line or 'ingest_time' in line:
            continue
        m = re.search(r'\bAS\s+(\w+)\s*$', line, re.IGNORECASE)
        if m:
            biz_cols.append(m.group(1))
        else:
            col = line.split('.')[-1].strip()
            if col and col != '*':
                biz_cols.append(col)

    # Extract source() call
    src_match = re.search(r"\{\{\s*source\('(.*?)',\s*'(.*?)'\)\s*\}\}", sql)
    src_schema = src_match.group(1) if src_match else 'unknown'
    src_table = src_match.group(2) if src_match else 'unknown'

    # Extract brand and source_system from final SELECT
    brand_match = re.search(r"'([^']+)'\s+AS\s+brand", sql)
    brand = brand_match.group(1) if brand_match else 'Unknown'
    
    sys_match = re.search(r"'([^']+)'\s+AS\s+source_system", sql)
    source_sys = sys_match.group(1) if sys_match else 'unknown'

    # Extract final SELECT columns (between last SELECT and FROM dedup)
    final_match = re.search(r'\)\s*SELECT\s+(.*?)\s*FROM\s+dedup', sql, re.DOTALL)
    final_body = final_match.group(1) if final_match else ''
    
    # Filter out brand/source_system lines from final columns
    final_lines = []
    for line in final_body.split('\n'):
        s = line.strip()
        if not s or 'AS brand' in s or 'AS source_system' in s:
            continue
        final_lines.append('    ' + s.rstrip(','))
    final_cols = ',\n'.join(final_lines)

    # Build record hash
    hash_parts = []
    for c in biz_cols:
        hash_parts.append(f"            COALESCE({c}::VARCHAR, '')")
    hash_expr = " || '|' ||\n".join(hash_parts)

    new_sql = f"""------------------------------------------------------------------------------------------------------------------------
-- {model_name}
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
{hist_body}
    FROM {{{{ source('{src_schema}', '{src_table}') }}}}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY {partition_key}
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY {partition_key}
        ) AS version_count,
        MD5(
{hash_expr}
        ) AS record_hash
    FROM history
)
SELECT
{final_cols},
    '{brand}' AS brand,
    '{source_sys}' AS source_system,
    ingest_date,
    ingest_ts,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
"""
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_sql)
    print(f"  UPDATED: {os.path.basename(filepath)}")


def main():
    files = sorted(glob.glob(os.path.join(RDL_ROOT, '**', '*.sql'), recursive=True))
    print(f"Found {len(files)} RDL models in {RDL_ROOT}\n")
    for f in files:
        transform(f)
    print("\nDone.")

if __name__ == '__main__':
    main()
