#!/usr/bin/env bash
# cicd/scripts/lib.sh — Shared library for CI/CD scripts.
# Source this file: source "$(dirname "$0")/lib.sh"

set -euo pipefail

# --- Logging -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_step()    { echo -e "\n${BLUE}[Step $1]${NC} $2"; }

# --- Environment validation --------------------------------------------------
require_env() {
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable not set: $var"
            exit 1
        fi
    done
}

# --- Snowflake execution ------------------------------------------------------
run_snowsql() {
    local sql_file="$1"
    local role="${2:-$SNOWFLAKE_ROLE}"

    log_info "Executing: $sql_file (role: $role)"
    snow sql --filename "$sql_file" \
        --role "$role" \
        --warehouse "${SNOWFLAKE_WAREHOUSE:-$warehouse}" \
        --connection "${SNOWFLAKE_CONNECTION:-default}"
}

# --- Deploy SQL files matching a pattern --------------------------------------
deploy_sql_dir() {
    local base_dir="$1"
    local pattern="$2"
    local role="${3:-cicd}"

    local role_var="SNOWFLAKE_ROLE"
    if [[ "$role" == "etl" ]]; then
        role_var="SNOWFLAKE_ROLE_ETL"
    fi

    local files
    files=$(find "$base_dir" -path "$pattern" -name "*.sql" | sort)

    if [[ -z "$files" ]]; then
        log_warn "No SQL files found matching: $pattern"
        return 0
    fi

    while IFS= read -r sql_file; do
        run_snowsql "$sql_file" "${!role_var:-$SNOWFLAKE_ROLE}"
    done <<< "$files"
}
