# Semantic View Instruction Macros

Each semantic view should have a corresponding macro file here that provides:

1. `sv_<name>_sql_generation()` — Hints for AI SQL generation (rounding rules, filter patterns, business logic)
2. `sv_<name>_question_categorization()` — Routing guidance (what this view covers vs. doesn't)

These macros are referenced in the semantic view SQL via:

```sql
AI_SQL_GENERATION $${{ sv_my_view_sql_generation() }}$$
AI_QUESTION_CATEGORIZATION $${{ sv_my_view_question_categorization() }}$$
```
