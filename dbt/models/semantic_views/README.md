# Semantic Views

Semantic views define the public analytical interface for your Cortex Agent. They:

- Use `{{ config(materialized='semantic_view') }}` (from the `dbt_semantic_view` package)
- Define TABLES, RELATIONSHIPS, FACTS, DIMENSIONS, and METRICS
- Include AI_SQL_GENERATION and AI_QUESTION_CATEGORIZATION instructions
- Include AI_VERIFIED_QUERIES for grounding the agent's SQL generation
- Are the ONLY models that should be consumed outside this project

## Structure

```sql
{{ config(materialized='semantic_view') }}

TABLES (
    <table_alias> AS (
        SELECT ... FROM {{ ref('fct_my_fact') }}
    ) PRIMARY KEY (id) COMMENT = 'Description'
)
RELATIONSHIPS (...)
FACTS (...)
DIMENSIONS (...)
METRICS (...)
COMMENT = 'Overall semantic view description'
AI_SQL_GENERATION $$instructions$$
AI_QUESTION_CATEGORIZATION $$instructions$$
AI_VERIFIED_QUERIES (...)
```

## Key Rules

1. **`AS` names must match physical column names** — you cannot rename simple column refs
2. **Use `WITH SYNONYMS (...)`** for alternate names the agent should understand
3. **Verified query SQL must use `__alias` logical table names** (e.g., `FROM __orders`)
4. **RELATIONSHIPS can only reference primary/unique keys** of the target table

See `docs/semantic-views-guide.md` for full documentation.
