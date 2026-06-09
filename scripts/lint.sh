#!/usr/bin/env bash
# scripts/lint.sh — runs sqlfluff, yamllint, markdownlint, and shellcheck.
# Used by: .githooks/pre-push, CI/CD pipeline
#
# Usage:
#   scripts/lint.sh          # run all linters (fail if any missing)
#   scripts/lint.sh --local  # skip missing linters instead of failing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOCAL_MODE=false
if [[ "${1:-}" == "--local" ]]; then
    LOCAL_MODE=true
fi

FAILED=0

# --- sqlfluff ---
if sqlfluff --version &>/dev/null; then
    echo -e "${YELLOW}[sqlfluff]${NC} Linting SQL files..."
    if sqlfluff lint dbt/models/ --config .sqlfluff --ignore parsing; then
        echo -e "${GREEN}[sqlfluff] Passed${NC}"
    else
        echo -e "${RED}[sqlfluff] Failed${NC}"
        FAILED=1
    fi
elif [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${YELLOW}[sqlfluff] Not installed — skipping${NC}"
else
    echo -e "${RED}[sqlfluff] Not installed — required in CI${NC}"
    FAILED=1
fi

# --- yamllint ---
if command -v yamllint &>/dev/null; then
    echo -e "\n${YELLOW}[yamllint]${NC} Linting YAML files..."
    if yamllint -c .yamllint.yml dbt/ --no-warnings; then
        echo -e "${GREEN}[yamllint] Passed${NC}"
    else
        echo -e "${RED}[yamllint] Failed${NC}"
        FAILED=1
    fi
elif [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${YELLOW}[yamllint] Not installed — skipping${NC}"
else
    echo -e "${RED}[yamllint] Not installed — required in CI${NC}"
    FAILED=1
fi

# --- markdownlint ---
if command -v markdownlint-cli2 &>/dev/null; then
    MDLINT_CMD="markdownlint-cli2"
elif command -v markdownlint &>/dev/null; then
    MDLINT_CMD="markdownlint"
else
    MDLINT_CMD=""
fi

if [[ -n "$MDLINT_CMD" ]]; then
    echo -e "\n${YELLOW}[markdownlint]${NC} Linting Markdown files..."
    if $MDLINT_CMD "**/*.md"; then
        echo -e "${GREEN}[markdownlint] Passed${NC}"
    else
        echo -e "${RED}[markdownlint] Failed${NC}"
        FAILED=1
    fi
elif [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${YELLOW}[markdownlint] Not installed — skipping${NC}"
else
    echo -e "${RED}[markdownlint] Not installed — required in CI${NC}"
    FAILED=1
fi

# --- shellcheck ---
if command -v shellcheck &>/dev/null; then
    echo -e "\n${YELLOW}[shellcheck]${NC} Linting shell scripts..."
    SHELL_FILES=$(find cicd/scripts scripts -name "*.sh" 2>/dev/null || true)
    if [[ -n "$SHELL_FILES" ]]; then
        if echo "$SHELL_FILES" | xargs shellcheck; then
            echo -e "${GREEN}[shellcheck] Passed${NC}"
        else
            echo -e "${RED}[shellcheck] Failed${NC}"
            FAILED=1
        fi
    else
        echo -e "${GREEN}[shellcheck] No shell files found${NC}"
    fi
elif [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${YELLOW}[shellcheck] Not installed — skipping${NC}"
else
    echo -e "${RED}[shellcheck] Not installed — required in CI${NC}"
    FAILED=1
fi

# --- snowflake template substitutions ---
if command -v python3 &>/dev/null; then
    echo -e "\n${YELLOW}[snowflake-templates]${NC} Rendering templates for dev..."
    if python3 scripts/render_snowflake_templates.py --env dev; then
        if grep -R --line-number --fixed-strings "{{" snowflake/rendered/dev &>/dev/null; then
            echo -e "${RED}[snowflake-templates] Failed — unresolved placeholders found${NC}"
            FAILED=1
        else
            echo -e "${GREEN}[snowflake-templates] Passed${NC}"
        fi
    else
        echo -e "${RED}[snowflake-templates] Failed — render errored${NC}"
        FAILED=1
    fi
elif [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${YELLOW}[snowflake-templates] python3 not installed — skipping${NC}"
else
    echo -e "${RED}[snowflake-templates] python3 required${NC}"
    FAILED=1
fi

# --- Result ---
echo ""
if [[ $FAILED -ne 0 ]]; then
    echo -e "${RED}Linting failed. Fix errors above.${NC}"
    exit 1
else
    echo -e "${GREEN}All linting passed.${NC}"
fi
