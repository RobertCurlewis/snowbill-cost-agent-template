# Health Check Skill

## Purpose

Run a data freshness and quality check across all data sources the agent depends on.

## When to Use

- User asks about data freshness, quality, or recency
- User asks you to run a health check or self-test
- Query results look suspicious (unexpected nulls, zero rows, implausible numbers)

## Steps

1. For each semantic view tool, run a simple recency query:

   ```text
   Check the maximum date/timestamp in the primary date column
   ```

2. Compare against expected freshness thresholds:
   - Daily data: should be within 24 hours
   - Weekly data: should be within 7 days

3. Report findings in a table:

   | Data Source | Latest Record | Expected Freshness | Status |
   |---|---|---|---|

4. Flag any sources that are stale or missing data.

## Output Format

Present a clear table with traffic-light status (Fresh / Stale / Missing) for each data source.
