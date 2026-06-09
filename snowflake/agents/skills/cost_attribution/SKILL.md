# Cost Attribution / Showback Skill

## Purpose

Allocate Snowflake spend (credits and currency) to teams, users, roles, query
tags, or databases — so cost can be shown back or charged back to whoever drives it.

## When to Use

- User asks who/what is driving cost, or to break spend down by team/user/role/tag
- User asks for chargeback, showback, or cost allocation

## Approach — use ACTUAL attributed credits

Prefer the **cost_analytics_analyst** tool: `QUERY_ATTRIBUTION_HISTORY` provides
**billed credits attributed to each query/user/warehouse** (`CREDITS_ATTRIBUTED_COMPUTE`)
— this is real attribution, **not** a compute-time estimate. Always date-filter
(default last 30 days).

> Fallback only if attribution data is unavailable: estimate via compute time ×
> warehouse-size multiplier (X-Small 1, Small 2, Medium 4, Large 8, …) from
> query_insights_analyst, and clearly label it an estimate.

## Team Attribution — 3 layers (try in order, combine what you find)

1. **Query tags** — group attributed credits by `QUERY_TAG` (teams that tag sessions, e.g. `team=ESG`).
2. **Object tags** — join `TAG_REFERENCES` (where `OBJECT_DOMAIN = 'WAREHOUSE'`, tag like team/cost_center/department) to attributed credits by warehouse.
3. **Name patterns** — match warehouse names with `WAREHOUSE_NAME ILIKE '%<team>%'` when neither tag layer is populated.

## Steps

1. **Confirm the dimension + period** (default: by `USER_NAME`, last 30 days).
2. **Pull attributed credits** per group via cost_analytics_analyst.
3. **For a named team**, apply the 3-layer approach and combine matches.
4. **Convert to currency** per the configured credit rate, showing credits and the converted amount.
5. **Reconcile**: compare attributed total to total account credits (`METERING_DAILY_HISTORY`); report the **unattributed remainder** (serverless features and idle warehouse time aren't tied to a query).
6. **Surface top contributors** within the leading group.

## Output Format

1. **Headline** — the top cost centre and its share.
2. **Showback table** — group, attributed credits, currency, % of attributed total.
3. **Top contributors** — drill-down within the leading group.
4. **Reconciliation** — attributed vs. total account credits; the unattributed remainder.
5. **Caveats** — attribution covers query compute only (not serverless/idle); ACCOUNT_USAGE latency.
