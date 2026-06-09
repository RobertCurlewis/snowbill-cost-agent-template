# Warehouse Right-Sizing & Idle Detection Skill

## Purpose

Find warehouses that are wasting credits — either sitting idle (paying for
warm compute that isn't running queries) or mis-sized (too big for their load,
or too small and queueing/spilling) — and recommend concrete sizing/suspend changes.

## When to Use

- User asks which warehouses are idle, underused, oversized, or wasteful
- User asks how to cut warehouse cost or tune auto-suspend / sizing
- User asks whether a warehouse is the right size

## Signals (from warehouse_efficiency_analyst)

- `CREDITS_USED` — total spend per warehouse/interval
- `AVG_RUNNING` — average concurrent queries actually running
- `AVG_QUEUED_LOAD`, `AVG_QUEUED_PROVISIONING`, `AVG_BLOCKED` — contention
- Cross-reference query_insights_analyst for `TOTAL_BYTES_SPILLED` and
  `WAREHOUSE_SIZE` per warehouse

## Steps

1. **Set scope.** Default to the last 14 days. State it.

2. **Pull per-warehouse load vs credits.** For each warehouse: total credits,
   average `AVG_RUNNING`, and the share of intervals with credits > 0 but
   `AVG_RUNNING` ≈ 0 (paying while idle).

3. **Classify each warehouse:**
   - **Idle / over-provisioned** — credits accrue with `AVG_RUNNING` near 0 for
     many intervals → auto-suspend too long, or warehouse kept warm. Recommend
     lowering `AUTO_SUSPEND`, or consolidating with another warehouse.
   - **Oversized** — no queueing, no spilling, low `AVG_RUNNING` → downsize.
   - **Undersized** — persistent `AVG_QUEUED_LOAD`/`AVG_BLOCKED` > 0 and/or
     spilling → scale **up** (size) for spilling, scale **out** (multi-cluster)
     for queueing.
   - **Healthy** — utilized, minimal queue, no spill.

4. **Quantify.** Convert credits to currency (per the cost rate). For idle/
   oversized warehouses, estimate the savings from the recommended change.

## Output Format

1. **Headline** — the most wasteful warehouse and the recommended action.
2. **Per-warehouse table** — warehouse, size, credits (+ $), avg running,
   queue/spill signals, verdict (Idle / Oversized / Undersized / Healthy).
3. **Recommendations** — ranked by estimated savings, each with the specific change.
4. **Caveats** — ACCOUNT_USAGE latency; load is averaged; validate before resizing.
