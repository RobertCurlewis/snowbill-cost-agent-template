# Cost Report Skill

## Purpose

Produce a clear, periodic Snowflake spend report — credits and currency — with
the top drivers, the trend versus the prior period, and anything notable. Built
for a regular FinOps cadence (weekly or monthly).

## When to Use

- User asks for a cost report, spend summary, weekly/monthly review, or "how are we doing on cost"
- User wants an exec-level overview of Snowflake spend

## Steps

1. **Set the period.** Default to the last 7 days vs. the previous 7 days
   (or month-to-date vs. last month if the user says "monthly"). State it.

2. **Total spend.** Use warehouse_efficiency_analyst for total warehouse
   `CREDITS_USED`, and serverless_usage_analyst for total serverless credits.
   Report combined credits and the currency total (per the cost rate).

3. **Top drivers:**
   - Top warehouses by credits (warehouse_efficiency_analyst)
   - Top users/roles by compute time (query_insights_analyst)
   - Serverless breakdown by feature (serverless_usage_analyst)

4. **Trend.** Compare each total and top driver to the prior period; show deltas
   (absolute and %).

5. **Notable changes.** Call out any warehouse, user, or feature that moved
   materially, plus any obvious waste (idle warehouses, heavy spilling) worth a
   follow-up — point to the relevant skill.

## Output Format

1. **Headline** — total spend (credits + currency) and the period-over-period change.
2. **Spend breakdown** — table: warehouse compute, serverless (by feature),
   each with credits, $, and Δ vs prior period.
3. **Top contributors** — top 5 warehouses and top 5 users/roles, with $ and Δ.
4. **Watch list** — notable movers and suggested follow-ups.
5. **Caveats** — ACCOUNT_USAGE latency; period boundaries.
