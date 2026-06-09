# Seeds

Seeds are CSV files that dbt loads directly into Snowflake. Use them for:

- Small reference/lookup data that changes rarely
- Bridge/mapping tables maintained by the team
- Evaluation datasets for agent testing

Place CSV files here with a corresponding `.yml` file for documentation and column types.
