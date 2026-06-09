# Semantic Views Guide

## What Are Semantic Views?

Semantic views are Snowflake objects that define a structured, AI-readable analytical
interface over your data. They tell Cortex Analyst:

- What tables and columns are available
- How tables relate to each other
- Which columns are measures (facts) vs. descriptors (dimensions)
- What pre-defined metrics exist
- How to generate correct SQL (via instructions and verified queries)

## Anatomy of a Semantic View

```sql
{{ config(materialized='semantic_view') }}

-- 1. TABLES: Define available data
TABLES (
    my_table AS (
        SELECT col1, col2, col3
        FROM {{ ref('my_model') }}
    ) PRIMARY KEY (col1)
      COMMENT = 'Description of this table'
)

-- 2. RELATIONSHIPS: How tables join
RELATIONSHIPS (
    my_table REFERENCES other_table (col1 = id)
)

-- 3. FACTS: Numeric/measurable columns
FACTS (
    my_table.col2 COMMENT = 'What this measures'
)

-- 4. DIMENSIONS: Descriptive/categorical columns
DIMENSIONS (
    my_table.col3 COMMENT = 'What this describes'
        WITH SYNONYMS ('alias1', 'alias2')
)

-- 5. METRICS: Pre-defined aggregations
METRICS (
    MY_METRIC AS SUM(my_table.col2) COMMENT = 'Sum of col2'
)

-- 6. Overall description
COMMENT = 'What this semantic view is for'

-- 7. AI instructions
AI_SQL_GENERATION $$instructions for SQL generation$$
AI_QUESTION_CATEGORIZATION $$what this view covers$$

-- 8. Verified queries (grounding examples)
AI_VERIFIED_QUERIES (
    QUERY (
        QUESTION = 'Example question'
        SQL = 'SELECT ... FROM __my_table AS my_table WHERE ...'
        VERIFIED_AT = 2024-01-01
        VERIFIED_BY = 'author'
    )
)
```

## Important Rules

1. **Column aliases must match physical names** — `orders.TOTAL_AMOUNT AS TOTAL_AMOUNT` works, but `AS REVENUE` does not for simple column references.

2. **Use `WITH SYNONYMS` for alternate names** — This lets users ask about "platform" when the column is called "channel".

3. **Verified queries use `__alias` table names** — NOT physical table names or `{{ ref() }}`. Use the table alias from TABLES prefixed with `__`.

4. **RELATIONSHIPS reference primary/unique keys only** — You cannot reference composite keys or non-key columns.

5. **ASOF relationships** for date joins — When joining to a date dimension, use ASOF to handle approximate date matching.

## Tips for Better Agent Performance

- Add 5-10 verified queries covering common questions
- Be specific in AI_SQL_GENERATION about rounding, defaults, and edge cases
- Use AI_QUESTION_CATEGORIZATION to prevent the agent from asking the wrong tool
- Add COMMENT on every fact and dimension — this is what the agent reads
- Use business-friendly names and synonyms
