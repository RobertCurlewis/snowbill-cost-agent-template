-- Semantic view: The public analytical interface for order data.
-- Copy to: dbt/models/semantic_views/sv_orders.sql

{{ config(materialized='semantic_view') }}

TABLES (
    orders AS (
        SELECT
            ORDER_ID,
            CUSTOMER_ID,
            ORDER_DATE,
            ORDER_STATUS,
            TOTAL_AMOUNT,
            DISCOUNT_AMOUNT,
            NET_AMOUNT,
            ITEM_COUNT,
            CHANNEL,
            REGION
        FROM {{ ref('fct_orders') }}
    ) PRIMARY KEY (ORDER_ID)
      COMMENT = 'Completed orders with revenue, discount, and channel details'
)

FACTS (
    orders.TOTAL_AMOUNT COMMENT = 'Gross order value before discounts',
    orders.DISCOUNT_AMOUNT COMMENT = 'Total discount applied to the order',
    orders.NET_AMOUNT COMMENT = 'Net order value after discounts (total - discount)',
    orders.ITEM_COUNT COMMENT = 'Number of items in the order'
)

DIMENSIONS (
    orders.ORDER_ID COMMENT = 'Unique order identifier',
    orders.CUSTOMER_ID COMMENT = 'Customer who placed the order',
    orders.ORDER_DATE COMMENT = 'Date the order was completed',
    orders.ORDER_STATUS COMMENT = 'Order status (always completed in this view)',
    orders.CHANNEL COMMENT = 'Sales channel'
        WITH SYNONYMS ('platform', 'source', 'touchpoint'),
    orders.REGION COMMENT = 'Geographic region of the order'
        WITH SYNONYMS ('area', 'territory', 'location')
)

METRICS (
    TOTAL_REVENUE AS SUM(orders.TOTAL_AMOUNT)
        COMMENT = 'Sum of gross order values',
    NET_REVENUE AS SUM(orders.NET_AMOUNT)
        COMMENT = 'Sum of net order values (after discounts)',
    TOTAL_DISCOUNT AS SUM(orders.DISCOUNT_AMOUNT)
        COMMENT = 'Sum of all discounts applied',
    ORDER_COUNT AS COUNT(orders.ORDER_ID)
        COMMENT = 'Total number of completed orders',
    AVG_ORDER_VALUE AS AVG(orders.NET_AMOUNT)
        COMMENT = 'Average net order value',
    AVG_BASKET_SIZE AS AVG(orders.ITEM_COUNT)
        COMMENT = 'Average items per order'
)

COMMENT = 'Order analytics: revenue, discounts, volumes, and channel/region performance'

AI_SQL_GENERATION $${{ sv_orders_sql_generation() }}$$
AI_QUESTION_CATEGORIZATION $${{ sv_orders_question_categorization() }}$$

AI_VERIFIED_QUERIES (
    QUERY (
        QUESTION = 'What was total revenue last week?'
        SQL = 'SELECT SUM(NET_AMOUNT) AS total_revenue
               FROM __orders AS orders
               WHERE orders.ORDER_DATE >= DATEADD(week, -1, CURRENT_DATE())
                 AND orders.ORDER_DATE < CURRENT_DATE()'
        VERIFIED_AT = 2024-01-01
        VERIFIED_BY = 'template_setup'
    ),
    QUERY (
        QUESTION = 'What is the average order value by channel?'
        SQL = 'SELECT
                   orders.CHANNEL,
                   AVG(orders.NET_AMOUNT) AS avg_order_value,
                   COUNT(orders.ORDER_ID) AS order_count
               FROM __orders AS orders
               GROUP BY orders.CHANNEL
               ORDER BY avg_order_value DESC'
        VERIFIED_AT = 2024-01-01
        VERIFIED_BY = 'template_setup'
    )
)
