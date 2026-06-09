# Cost Attribution / Showback Skill

## Purpose

Allocate Snowflake spend (credits and currency) to teams, users, roles, query
tags, or databases — so cost can be shown back or charged back to the people
who drive it.

## When to Use

- User asks who/what is driving cost, or to break spend down by team/user/role/tag/database
- User asks for chargeback, showback, or cost allocation

## Approach & Caveat

`QUERY_HISTORY` has **no billed credit per query**, so attribution is an
**estimate**: allocate by compute time weighted by warehouse size
(`TOTAL_SECONDS` × size multiplier — X-Small 1, Small 2, Medium 4, Large 8,
X-Large 16, 2X-Large 32, …). Always state that the split is an estimate. Where
possible, reconcile the total against actual warehouse `CREDITS_USED` from
warehouse_efficiency_analyst and note any gap (idle/serverless credits aren't
attributable to a query).

## Steps

1. **Pick the dimension.** Default to `ROLE_NAME` (usually the team proxy); also
   support `USER_NAME`, `QUERY_TAG`, `DATABASE_NAME`. Confirm period (default
   last 30 days).

2. **Compute the allocation basis.** Use query_insights_analyst to get weighted
   compute time per group (per the size multiplier above).

3. **Convert to share and cost.** Turn each group's weighted time into a % of
   total, then apply that % to total warehouse credits, and convert to currency
   (per the cost rate).

4. **Reconcile.** Compare the attributed total to actual warehouse credits for
   the period; report the unattributed remainder (idle + serverless).

5. **Surface top contributors** within each group (e.g. top users within a role).

## Output Format

1. **Headline** — the top cost center and its share.
2. **Showback table** — group, weighted compute, estimated credits, estimated $,
   % of total.
3. **Top contributors** — drill-down within the leading groups.
4. **Reconciliation** — attributed vs. actual credits, and the unattributed remainder.
5. **Caveats** — allocation is a compute-time estimate, not billed credits;
   ACCOUNT_USAGE latency.
