-- Instruction macro for the orders semantic view.
-- Copy to: dbt/macros/semantic_view_instructions/sv_orders.sql

{% macro sv_orders_sql_generation() %}
When querying revenue, default to NET_AMOUNT (after discounts) unless the user
explicitly asks for gross revenue (TOTAL_AMOUNT).

Round all currency values to 2 decimal places.
Round percentages to 1 decimal place.

Default time period is the last 7 days if not specified.
Use ORDER_DATE for all time-based filtering.

For time series, GROUP BY ORDER_DATE.
For channel comparisons, GROUP BY CHANNEL.
For regional analysis, GROUP BY REGION.
{% endmacro %}

{% macro sv_orders_question_categorization() %}
This view answers questions about:
- Order volumes and trends over time
- Revenue (gross and net) and average order value
- Discount analysis and discount rates
- Channel/platform performance comparisons
- Regional performance breakdowns
- Basket size analysis

This view does NOT answer questions about:
- Individual products or SKUs (use the product analyst)
- Customer demographics or segments (use customer analyst)
- Inventory or stock levels
- Marketing campaign attribution
- Delivery/fulfilment operations

If asked about products within orders, redirect to the product analyst tool.
{% endmacro %}
