#!/bin/bash
# Teardown Script — removes all AWS resources
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CDK_DIR="$PROJECT_DIR/cdk"

echo "⚠  WARNING: This will destroy ALL resources"
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then echo "Aborted."; exit 0; fi

cd "$PROJECT_DIR"
source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate 2>/dev/null

echo "🗑️  Destroying CloudFormation stack..."
cd "$CDK_DIR"
cdk destroy --force
echo "✓ Stack destroyed"

rm -f "$PROJECT_DIR/cdk-outputs.json" "$PROJECT_DIR/lambda-response.json"
echo "✅ Teardown Complete! No further charges will be incurred."
