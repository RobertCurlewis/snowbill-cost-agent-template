# Expensive Query Triage Skill

## Purpose

Find the biggest, most costly queries, explain *why* each is expensive, and
recommend specific fixes — so the user can cut spend on the queries that matter
most, not just the longest-running ones.

## When to Use

- User asks for the most expensive / biggest / heaviest / costliest queries
- User asks which queries to optimize, or where query cost is concentrated
- User asks about a specific user's, role's, or warehouse's worst queries

## Cost Model

`QUERY_HISTORY` has no per-query credit figure, so estimate relative cost as:

> **estimated cost ≈ TOTAL_SECONDS × warehouse-size multiplier**

Credits/hour double with each warehouse size, so weight compute time by size:

| WAREHOUSE_SIZE | Multiplier |
|---|---|
| X-Small | 1 |
| Small | 2 |
| Medium | 4 |
| Large | 8 |
| X-Large | 16 |
| 2X-Large | 32 |
| 3X-Large | 64 |
| 4X-Large | 128 |

A 60s query on a Large warehouse (×8) costs ~8× a 60s query on X-Small. Always
rank by this weighted cost, not raw `TOTAL_SECONDS`.

## Steps

1. **Set scope.** Confirm the period (default: last 7 days) and any filter
   (user, role, warehouse). State the defaults you used.

2. **Rank by estimated cost.** Use the `query_insights_analyst` tool to pull the
   top queries by `TOTAL_SECONDS` weighted by `WAREHOUSE_SIZE` (per the table
   above). Return `QUERY_ID`, `USER_NAME`, `ROLE_NAME`, `WAREHOUSE_NAME`,
   `WAREHOUSE_SIZE`, `QUERY_TYPE`, `TOTAL_SECONDS`, `BYTES_SCANNED`.

3. **Separate one-offs from recurring.** Group by `QUERY_TAG` and by similar
   `QUERY_TYPE`/user patterns. A query that runs 100×/day matters far more than
   a single heavy ad-hoc query — call this out explicitly.

4. **Diagnose each top query** from its efficiency signals:
   - `PARTITION_SCAN_RATIO` near 1.0 → full table scan (poor pruning)
   - `TOTAL_BYTES_SPILLED` > 0 → spilling (undersized warehouse or heavy join/sort)
   - high `COMPILATION_SECONDS` → overly complex query / many objects
   - high `QUEUE_WAIT_SECONDS` → warehouse contention, not the query itself
   - low `CACHE_HIT_PERCENT` on repeated patterns → re-scanning cold data

5. **Recommend a fix per query**, tied to the diagnosis:
   - Full scan → add a WHERE filter, cluster the table, or add search optimization
   - Spilling → right-size the warehouse up, or reduce the working set / rewrite
   - High compile → simplify, materialize intermediates, reduce view nesting
   - Queueing → scale-out (multi-cluster) or move the workload off a busy warehouse
   - Recurring + cacheable → schedule/result-cache, or pre-aggregate

6. **Quantify the prize.** For the top offenders, state the rough credit impact
   (weighted cost × frequency) so fixes can be prioritized by savings.

## Output Format

1. **Headline** — the single most expensive query/pattern and its driver.
2. **Top offenders** — ranked table: query, user, warehouse (size), total seconds,
   estimated relative cost, scanned, spilled, scan ratio, runs in period.
3. **Diagnosis + fix** — one line per top query linking the signal to the action.
4. **Caveats** — cost is a compute-time estimate (not billed credits);
   ACCOUNT_USAGE latency; period boundaries; small samples.
