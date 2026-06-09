# Semantic Views (Snowflake-managed)

This directory is intentionally empty. Semantic views for this project are managed
via dbt using the `dbt_semantic_view` package (see `dbt/models/semantic_views/`).

The rendered SQL is deployed by CI/CD from `snowflake/rendered/` after template
variable substitution.
