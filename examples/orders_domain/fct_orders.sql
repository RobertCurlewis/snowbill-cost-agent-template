-- Fact model: Completed orders at order grain.
-- Copy to: dbt/models/marts/fct_orders.sql

SELECT
    order_id,
    customer_id,
    order_date,
    order_status,
    total_amount,
    discount_amount,
    net_amount,
    item_count,
    channel,
    region
FROM {{ ref('stg_orders') }}
WHERE order_status = 'completed'
