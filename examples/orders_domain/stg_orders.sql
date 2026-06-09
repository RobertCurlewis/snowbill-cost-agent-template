-- Staging model: 1:1 mapping from source, with type casting and renaming.
-- Copy to: dbt/models/staging/stg_orders.sql

SELECT
    order_id::NUMBER AS order_id,
    customer_id::NUMBER AS customer_id,
    order_date::DATE AS order_date,
    LOWER(order_status) AS order_status,
    total_amount::DECIMAL(12, 2) AS total_amount,
    discount_amount::DECIMAL(12, 2) AS discount_amount,
    (total_amount - discount_amount)::DECIMAL(12, 2) AS net_amount,
    item_count::NUMBER AS item_count,
    LOWER(channel) AS channel,
    LOWER(region) AS region,
    created_at::TIMESTAMP_NTZ AS created_at
FROM {{ source('sales', 'RAW_ORDERS') }}
WHERE NOT COALESCE(is_test, FALSE)
