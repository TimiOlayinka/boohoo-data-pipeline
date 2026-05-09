#!/bin/bash
# ============================================================================
# Deploy Script — Data Architecture Portfolio
# ============================================================================
# Usage: ./scripts/deploy.sh
#
# Prerequisites:
#   - AWS CLI configured with credentials
#   - AWS CDK v2 installed (npm install -g aws-cdk)
#   - Python 3.12+ with venv
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CDK_DIR="$PROJECT_DIR/cdk"

echo "============================================"
echo "  Data Architecture Portfolio — Deploy"
echo "============================================"
echo ""

# ------------------------------------------------------------------
# Step 1: Install Python dependencies
# ------------------------------------------------------------------
echo "📦 Step 1: Installing Python dependencies..."
cd "$PROJECT_DIR"

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate 2>/dev/null
pip install -q -r requirements.txt

echo "   ✓ Dependencies installed"
echo ""

# ------------------------------------------------------------------
# Step 2: CDK Bootstrap (first time only)
# ------------------------------------------------------------------
echo "🏗️  Step 2: Bootstrapping CDK..."
cd "$CDK_DIR"

cdk bootstrap 2>/dev/null || echo "   ℹ Already bootstrapped (or bootstrap failed — check AWS credentials)"
echo ""

# ------------------------------------------------------------------
# Step 3: Deploy the stack
# ------------------------------------------------------------------
echo "🚀 Step 3: Deploying CloudFormation stack..."
cdk deploy --require-approval never --outputs-file "$PROJECT_DIR/cdk-outputs.json"

echo "   ✓ Stack deployed successfully"
echo ""

# ------------------------------------------------------------------
# Step 4: Extract outputs
# ------------------------------------------------------------------
echo "📋 Step 4: Reading stack outputs..."

if [ -f "$PROJECT_DIR/cdk-outputs.json" ]; then
    echo ""
    echo "   Stack outputs:"
    cat "$PROJECT_DIR/cdk-outputs.json" | python3 -m json.tool
    echo ""
fi

# ------------------------------------------------------------------
# Step 5: Invoke data generator for initial load
# ------------------------------------------------------------------
echo "🎲 Step 5: Generating initial data..."

aws lambda invoke \
    --function-name portfolio-data-generator \
    --payload '{"initial_load": true, "n_customers": 5000, "n_products": 500, "n_orders": 50000}' \
    --cli-binary-format raw-in-base64-out \
    "$PROJECT_DIR/lambda-response.json"

echo "   ✓ Data generator invoked"
echo ""

if [ -f "$PROJECT_DIR/lambda-response.json" ]; then
    echo "   Lambda response:"
    cat "$PROJECT_DIR/lambda-response.json" | python3 -m json.tool
    echo ""
fi

# ------------------------------------------------------------------
# Step 6: Wait for Redshift loading
# ------------------------------------------------------------------
echo "⏳ Step 6: Waiting 60 seconds for Redshift loader to process..."
sleep 60
echo "   ✓ Done waiting"
echo ""

# ------------------------------------------------------------------
# Step 7: Create analytical views
# ------------------------------------------------------------------
echo "📊 Step 7: Creating analytical views in Redshift..."

# Read the workgroup name from outputs
WORKGROUP="portfolio-wg"
DATABASE="portfolio_db"

# Execute each view creation via Data API
SQL_FILE="$PROJECT_DIR/sql/create_views.sql"

if [ -f "$SQL_FILE" ]; then
    # Split SQL file by semicolons and execute each statement
    while IFS= read -r -d ';' sql_statement; do
        # Skip empty statements
        trimmed=$(echo "$sql_statement" | tr -d '[:space:]')
        if [ -n "$trimmed" ] && [ "$trimmed" != "--" ]; then
            echo "   Executing view creation..."
            aws redshift-data execute-statement \
                --workgroup-name "$WORKGROUP" \
                --database "$DATABASE" \
                --sql "$sql_statement;" \
                --output text \
                --query 'Id' 2>/dev/null || echo "   ⚠ Failed to execute statement"
            sleep 2
        fi
    done < "$SQL_FILE"
    echo "   ✓ Views created"
else
    echo "   ⚠ SQL file not found: $SQL_FILE"
fi

echo ""
echo "============================================"
echo "  ✅ Deployment Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open AWS Console → Redshift → Query Editor v2"
echo "  2. Connect to workgroup: $WORKGROUP"
echo "  3. Verify tables: SELECT COUNT(*) FROM fact_orders;"
echo "  4. Connect Google Looker Studio (see docs/looker_studio_setup.md)"
echo ""
