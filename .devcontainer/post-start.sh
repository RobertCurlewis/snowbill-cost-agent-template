#!/usr/bin/env bash
set -euo pipefail

echo "=== Post-start validation ==="

# Check Snowflake credentials
if [ -d "$HOME/.snowflake" ]; then
    echo "✓ Snowflake config directory found"
else
    echo "⚠ No ~/.snowflake directory. Run: snow connection add"
fi

# Check dbt profile
if [ -f "$HOME/.dbt/profiles.yml" ]; then
    echo "✓ dbt profiles.yml found"
else
    echo "⚠ No ~/.dbt/profiles.yml. Configure your dbt profile."
fi

echo "=== Post-start complete ==="
