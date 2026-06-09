# Staging Models

Staging models are the first transformation layer. They:

- Map 1:1 to source tables
- Cast columns to correct types
- Rename columns to follow conventions (lowercase, underscores)
- Apply minimal filtering (e.g., remove test records)
- Do NOT join to other tables

## Naming Convention

`stg_<source_name>_<table_name>.sql`

## Example

```sql
{{ config(materialized='view') }}

SELECT
    id::NUMBER AS order_id,
    LOWER(status) AS order_status,
    amount::DECIMAL(12,2) AS order_amount,
    created_at::TIMESTAMP_NTZ AS created_at
FROM {{ source('my_source', 'ORDERS') }}
WHERE NOT is_test_record
```
