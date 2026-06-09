#!/usr/bin/env bash
set -euo pipefail

echo "=== Post-create setup ==="

# Activate git hooks
git config core.hooksPath .githooks
echo "Git hooks configured."

# Install dbt packages
if [ -f dbt/packages.yml ]; then
    cd dbt && dbt deps && cd ..
    echo "dbt packages installed."
fi

echo "=== Post-create complete ==="
