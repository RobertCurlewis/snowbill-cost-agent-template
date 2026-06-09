# Agent Evaluation Guide

Cortex Agent Evaluations score your agent's answers against a set of example
questions, so you can catch quality regressions as you change the agent.

## Why Evaluate?

Regular evaluation ensures your agent:

- Answers questions correctly
- Uses the right tools
- Doesn't hallucinate
- Maintains quality as you add features

## How It Works

1. A **seed table** (`AGENT_EVAL_DATASET`) holds your example questions and,
   optionally, the expected answer ("ground truth").
2. A **config YAML** (`agent_eval.yaml`) on an internal stage tells Snowflake
   which agent, dataset, and metrics to use.
3. `EXECUTE_AI_EVALUATION('START', …)` runs the agent over every question (as a
   background task) and scores each answer.
4. `GET_AI_EVALUATION_DATA(…)` returns the per-question scores.

The objects (`AGENT_EVAL_DATASET`, `AGENT_EVAL_STAGE`) and config live in
`snowflake/evals/`.

## Setup

### 1. Create the eval objects

Run [`snowflake/evals/create_eval_dataset.sql`](../snowflake/evals/create_eval_dataset.sql).
It creates the seed table and the config stage, and seeds a few example rows.
This also runs in CI when `DEPLOY_EVALS=true`.

### 2. Populate the seed table

Replace the example rows with questions representative of your agent. Each row:

- `input_query` (VARCHAR) — the user question.
- `ground_truth` (VARIANT) — `{"ground_truth_output": "<expected answer>"}`.
  Required by `answer_correctness`; may be `NULL` for rows you only score with
  `logical_consistency` (which is reference-free).

### 3. Grant task privileges

An evaluation runs as a Snowflake task, so the role needs:

```sql
GRANT CREATE TASK ON SCHEMA DB.SCHEMA TO ROLE <role>;
-- account-level grant — must be run by ACCOUNTADMIN:
GRANT EXECUTE TASK ON ACCOUNT TO ROLE <role>;
```

### 4. Upload the config and run

Render templates, upload the config to the stage, then start the run. From the
repo root:

```bash
python scripts/render_snowflake_templates.py --env dev
snow stage copy snowflake/rendered/dev/evals/agent_eval.yaml \
  @DB.SCHEMA.AGENT_EVAL_STAGE --overwrite
```

Then run the statements in
[`snowflake/evals/run_eval.sql`](../snowflake/evals/run_eval.sql): `START`, poll
`STATUS` until `COMPLETED`, then read scores with `GET_AI_EVALUATION_DATA`.

`run_name` must be **unique** per run — bump the suffix each time.

## Config YAML

[`agent_eval.yaml`](../snowflake/evals/agent_eval.yaml) has three parts:

- `dataset:` — imports the seed table into a dataset on the **first** run.
  Remove this block for later runs against the same dataset.
- `evaluation:` — the agent (`agent_name`, `agent_type: "CORTEX AGENT"`) and the
  `source_metadata` pointing at the dataset.
- `metrics:` — the metrics to compute.

## Metrics

- **answer_correctness** — Does the answer match `ground_truth_output`?
- **logical_consistency** — Is the answer internally consistent? (reference-free)

## Reading Results

`GET_AI_EVALUATION_DATA` returns one row per (question × metric):

- `EVAL_AGG_SCORE` — the score (1.0 = best).
- `METRIC_STATUS` — per-row judge status. A non-200 code (e.g. a context-window
  limit on a very long answer) means the **judge** failed, not that the agent
  answered badly — re-check those manually.

## Best Practices

- Start with 10-20 questions covering core use cases.
- Add questions for edge cases as you discover them.
- Re-run evaluation after every agent change.
- Track scores over time to catch regressions.
