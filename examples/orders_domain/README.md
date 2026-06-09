# Example: Orders Domain

This example shows a complete data domain implementation from source to agent tool.

## Files

- `stg_orders.sql` — Staging model
- `fct_orders.sql` — Fact table
- `sv_orders.sql` — Semantic view
- `sv_orders_instructions.sql` — Instruction macro
- `schema.yml` — Model documentation
- `agent_tool_config.yml` — How to add this as an agent tool

## How to Use

Copy these files into your `dbt/models/` directory (adjusting paths) to see a working
end-to-end example. Then follow the instructions in `agent_tool_config.yml` to wire
the semantic view to your agent.
