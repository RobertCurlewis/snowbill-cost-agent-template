# Intermediate Models

Intermediate models sit between staging and marts. They:

- Join staging models together
- Apply business logic and calculations
- Deduplicate or reshape data
- Are NOT exposed to end users (internal only)

## Naming Convention

`int_<description>.sql`

## Example

```sql
{{ config(materialized='table') }}

SELECT
    o.order_id,
    o.order_amount,
    c.customer_name,
    c.customer_segment
FROM {{ ref('stg_orders') }} AS o
INNER JOIN {{ ref('stg_customers') }} AS c
    ON o.customer_id = c.customer_id
```
