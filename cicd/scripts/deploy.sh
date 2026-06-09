#!/usr/bin/env bash
# cicd/scripts/deploy.sh — Orchestrate Snowflake object deployment.
#
# Deploys in dependency order:
#   1. Tags
#   2. Stages
#   3. Semantic views (if managed outside dbt)
#   4. Agents
#   5. Skill files (uploaded to internal stage)
#   6. Eval SQL (tasks + datasets)
#
# Required environment variables:
#   ENV              — "dev" or "prod"
#   CONSUME_DB       — Snowflake database name
#   SNOWFLAKE_ROLE   — Snowflake role for deployment
#
# Usage:
#   ENV=dev CONSUME_DB=DEV_DB SNOWFLAKE_ROLE=CICD_ROLE cicd/scripts/deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=cicd/scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

# Validate
require_env ENV CONSUME_DB SNOWFLAKE_ROLE

if [[ "${ENV}" != "dev" && "${ENV}" != "prod" ]]; then
    log_error "ENV must be 'dev' or 'prod' — got '${ENV}'"
    exit 1
fi

RENDERED_DIR="snowflake/rendered/${ENV}"
log_info "Deploying from: ${RENDERED_DIR}"

# Step 1: Tags
log_step 1 "Deploy tags"
deploy_sql_dir "${RENDERED_DIR}" "*/tags/*"

# Step 2: Stages
log_step 2 "Deploy stages"
deploy_sql_dir "${RENDERED_DIR}" "*/stages/*"

# Step 3: Upload skill files — MUST precede agents. The agent spec references
# skills by stage path, and CREATE AGENT validates they exist.
log_step 3 "Upload skill files"
"${SCRIPT_DIR}/upload_skills.sh"

# Step 4: Agents
log_step 4 "Deploy agents"
deploy_sql_dir "${RENDERED_DIR}" "*/agents/*"

# Step 5: Deploy eval SQL (opt-in — requires the AGENT_EVAL_QUERIES seed table)
if [[ "${DEPLOY_EVALS:-false}" == "true" ]]; then
    log_step 5 "Deploy eval SQL"
    deploy_sql_dir "${RENDERED_DIR}" "*/evals/*"
else
    log_info "Skipping eval SQL (set DEPLOY_EVALS=true once the eval seed exists)."
fi

# Done
echo ""
log_success "All Snowflake objects deployed for '${ENV}'."
