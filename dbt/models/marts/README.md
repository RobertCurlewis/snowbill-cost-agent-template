# Mart Models (Facts & Dimensions)

Mart models are the final analytical tables consumed by the semantic views and agent. They:

- Represent business entities (dimensions) or business events (facts)
- Are fully denormalized or star-schema shaped
- Have comprehensive documentation and tests
- Are the primary input to semantic views

## Naming Convention

- `fct_<business_event>.sql` — Fact tables (transactional grain)
- `dim_<business_entity>.sql` — Dimension tables (descriptive attributes)

## Example

```sql
{{ config(materialized='table') }}

SELECT
    order_id,
    customer_id,
    order_date,
    platform,
    order_amount,
    discount_amount,
    net_amount,
    item_count,
    fulfilment_status
FROM {{ ref('int_orders_enriched') }}
```
