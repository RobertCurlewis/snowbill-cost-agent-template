# Project Guidelines — Snowflake Cortex Agent

## About This Project

This is a Snowflake Cortex-based data agent that combines structured analytics data with AI to help teams make better data-driven decisions. Users access the agent via **Snowflake Intelligence UI**.

## Architecture

- **Agent framework**: Snowflake Cortex Agents (orchestrates Cortex Analyst + Cortex Search)
- **Semantic layer**: Snowflake Semantic Views, managed via dbt using `dbt_semantic_view` package
- **Data transformation**: dbt (Cloud or Core)
- **CI/CD**: GitHub Actions
- **Configuration**: `cookiecutter.yml` (project-level settings)

## Code Conventions

### SQL & dbt

- All dbt models live in `dbt/models/`
- Default materialisation is `table` (configured in `dbt_project.yml`)
- Semantic views use `materialized='semantic_view'` (from `dbt_semantic_view` package)
- Naming: lowercase, underscores, descriptive names
- Prefix staging models with `stg_`, intermediate with `int_`, facts with `fct_`, dimensions with `dim_`
- Semantic views prefixed with `sv_`

### Semantic Views

- Define facts, dimensions, and metrics with clear business descriptions
- Use `WITH SYNONYMS` for alternate names
- Every metric needs an aggregation method and plain-English description
- **FACTS/DIMENSIONS `AS` names must match physical column names**
- **Verified query SQL must use `__alias` logical table names** (e.g. `FROM __orders AS orders`)
- **RELATIONSHIPS can only reference primary/unique keys** of the target table

### Agent Configuration

- System prompt defines persona, scope, domain knowledge, and output conventions
- Orchestration instructions specify when to use each tool
- Skills are prose-only Markdown playbooks (no code execution)
- Always include verified queries for grounding

### Template Variables

Files in `snowflake/` use `{{ variable }}` placeholders:

- `{{ database }}` — Target database
- `{{ schema }}` — Target schema
- `{{ warehouse }}` — Query warehouse
- `{{ agent_name }}` — Agent object name
- `{{ agent_description }}` — Agent comment
- `{{ include('file.ext') }}` — Inline file content

## Development Workflow

1. Create a feature branch (never commit directly to main)
2. Write/modify dbt models
3. Run `dbt run && dbt test` to verify
4. Deploy to dev: `python scripts/render_snowflake_templates.py --env dev`
5. Test agent in Snowflake Intelligence UI
6. Open PR/MR for review
7. CI/CD deploys to prod on merge/tag

## Build and Test

```bash
# Install dbt dependencies
cd dbt && dbt deps

# Run dbt models
dbt run

# Test dbt models
dbt test

# Deploy semantic views only
dbt run --select tag:semantic_view

# Render and deploy Snowflake objects
python scripts/render_snowflake_templates.py --env dev
bash cicd/scripts/deploy.sh
```

## Linting

```bash
# Run all linters
scripts/lint.sh --local

# Auto-fix SQL
sqlfluff fix dbt/models/ --config .sqlfluff

# Auto-fix Markdown
markdownlint-cli2 --fix '**/*.md'
```

## Adding a New Data Domain

1. Add source in `dbt/models/sources.yml`
2. Create staging model: `dbt/models/staging/stg_<name>.sql`
3. Create mart model: `dbt/models/marts/fct_<name>.sql` or `dim_<name>.sql`
4. Create semantic view: `dbt/models/semantic_views/sv_<name>.sql`
5. Create instruction macro: `dbt/macros/semantic_view_instructions/sv_<name>.sql`
6. Register tool in `snowflake/agents/agent-specification.yml`
7. Add routing in orchestration instructions
8. Add verified queries
9. Test end-to-end
