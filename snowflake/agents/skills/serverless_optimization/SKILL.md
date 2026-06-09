# Serverless Optimization Skill

## Purpose

Review serverless feature credits — automatic clustering, search optimization,
Snowpipe, and replication — and flag where they may not be worth the cost, so
spend on managed features can be trimmed.

## When to Use

- User asks about serverless spend, automatic clustering, search optimization,
  Snowpipe, or replication costs
- User asks where serverless credits are going or how to reduce them

## Signals (from serverless_usage_analyst)

- Automatic clustering — `CREDITS_USED` by `DATABASE_NAME` / `SCHEMA_NAME` / `TABLE_NAME`
- Search optimization — `CREDITS_USED` by table
- Snowpipe — `CREDITS_USED` and trend over `START_TIME`
- Replication — `CREDITS_USED` by `DATABASE_NAME`

## Steps

1. **Set scope.** Default to the last 30 days. State it.

2. **Break down by feature.** Total credits (and currency, per the cost rate)
   for each: automatic clustering, search optimization, Snowpipe, replication.
   Show each feature's share of serverless spend.

3. **Find the expensive objects:**
   - Top tables by automatic clustering credits
   - Top tables by search optimization credits
   - Snowpipe credit trend (rising/steady/falling)
   - Replication credits by database

4. **Flag likely low-value spend.** Automatic clustering or search optimization
   that costs a lot is only justified if it speeds enough queries. Flag the
   highest-cost tables for review and recommend validating the benefit (e.g.
   compare against query patterns) before keeping the feature enabled.

5. **Recommend.** For flagged tables, suggest reviewing/disabling the feature;
   for Snowpipe, note whether batching could reduce per-file overhead; for
   replication, confirm the target is still needed.

## Output Format

1. **Headline** — total serverless spend (credits + $) and the largest feature.
2. **By feature** — table: feature, credits, $, share, trend.
3. **Expensive objects** — top tables/databases per feature with credits + $.
4. **Recommendations** — flagged items to review, ranked by cost.
5. **Caveats** — feature value needs query-side validation (not in these views);
   ACCOUNT_USAGE latency.
