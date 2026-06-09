#!/usr/bin/env bash
# cicd/scripts/upload_skills.sh — Upload skill .md files to Snowflake internal stage.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cicd/scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env ENV CONSUME_DB SNOWFLAKE_ROLE

SKILLS_DIR="snowflake/agents/skills"
STAGE_PATH="@${CONSUME_DB}.${SNOWFLAKE_SCHEMA:-MY_SCHEMA}.AGENT_SKILLS_STAGE"

if [[ ! -d "$SKILLS_DIR" ]]; then
    log_warn "Skills directory not found: $SKILLS_DIR"
    exit 0
fi

# Find all skill directories (each containing SKILL.md)
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="${skill_dir}SKILL.md"

    if [[ ! -f "$skill_file" ]]; then
        log_warn "No SKILL.md found in $skill_dir — skipping"
        continue
    fi

    log_info "Uploading skill: $skill_name"
    snow stage copy "$skill_file" "${STAGE_PATH}/skills/${skill_name}/" \
        --overwrite \
        --connection "${SNOWFLAKE_CONNECTION:-default}" \
        --role "$SNOWFLAKE_ROLE"
done

log_success "All skills uploaded."
