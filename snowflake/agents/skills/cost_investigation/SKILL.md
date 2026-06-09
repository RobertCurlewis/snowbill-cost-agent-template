# Cost Investigation Skill

## Purpose

Diagnose *why* Snowflake spend changed and surface concrete optimization
opportunities — turning "our bill went up" into a ranked, actionable answer.

## When to Use

- User asks why credits/spend increased (or spiked) over a period
- User asks where they are wasting credits or how to reduce cost
- User asks for the biggest cost drivers or optimization opportunities

## Steps

1. **Establish the comparison.** Confirm the period and a comparator (vs. the
   prior equivalent period). If the user didn't give one, default to the last
   7 days vs. the previous 7 days, and say so.

2. **Find where credits moved.** Use the warehouse_efficiency_analyst to get
   total credits per warehouse for both periods and rank warehouses by the
   increase. Note compute vs. cloud-services split.

3. **Attribute the movement.** For the warehouse(s) that grew most, use the
   query_insights_analyst to find the users, roles, and query types driving the
   compute time in that window.

4. **Check serverless.** Use the serverless_usage_analyst to see whether
   automatic clustering, Snowpipe, replication, or search optimization credits
   changed materially.

5. **Spot waste.** Flag efficiency red flags from query_insights:
   - Queries with heavy disk spilling (undersized warehouse or heavy query)
   - Full table scans (partition scan ratio near 1.0)
   - Significant queueing / warehouse congestion
   - Low cache hit rates on repeated query patterns

6. **Recommend.** Tie each finding to a specific action (e.g. resize/auto-suspend
   a warehouse, add clustering, rewrite a scan-heavy query, consolidate idle
   warehouses). Order recommendations by estimated credit impact.

## Output Format

1. **Headline** — the single biggest driver of the change.
2. **Breakdown** — table of top movers (warehouse / user / feature) with credits
   this period, last period, and delta.
3. **Optimization opportunities** — ranked list, each with the action and why.
4. **Caveats** — ACCOUNT_USAGE latency, period boundaries, any small samples.
