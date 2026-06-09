# Agent Evaluation Guide

## Why Evaluate?

Regular evaluation ensures your agent:

- Answers questions correctly
- Uses the right tools
- Doesn't hallucinate
- Maintains quality as you add features

## Setup

### 1. Create Evaluation Questions

Add question-answer pairs to `dbt/seeds/agent_eval_queries.csv`:

```csv
INPUT_QUERY,GROUND_TRUTH_OUTPUT
"What was total revenue last week?","{""answer_contains"": [""revenue"", ""last week""]}"
"How many orders yesterday?","{""answer_contains"": [""orders"", ""yesterday""]}"
```

### 2. Load the Seed

```bash
cd dbt && dbt seed --select agent_eval_queries
```

### 3. Create the Evaluation Dataset

```sql
SELECT SYSTEM$CREATE_EVALUATION_DATASET(
    'DB.SCHEMA.AGENT_EVAL_DATASET',
    'SNOWFLAKE.ML.QUESTION_ANSWER',
    'DB.SCHEMA.AGENT_EVAL_QUERIES'
);
```

### 4. Run Evaluation

```sql
SELECT SNOWFLAKE.CORTEX.EXECUTE_AI_EVALUATION('AGENT_EVAL_CONFIG');
```

## Metrics

- **answer_correctness** — Does the answer match the ground truth?
- **logical_consistency** — Is the reasoning sound?

## Automation

Deploy `snowflake/evals/create_eval_task.sql` to run evaluations on a schedule
(e.g., weekly). Monitor results for regressions.

## Best Practices

- Start with 10-20 questions covering core use cases
- Add questions for edge cases as you discover them
- Re-run evaluation after every agent change
- Track scores over time to catch regressions
