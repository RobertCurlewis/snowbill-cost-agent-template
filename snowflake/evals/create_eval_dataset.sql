-- Set up the evaluation seed table and config stage for Cortex Agent Evaluations.
--
-- Cortex Agent Evaluations (GA) score an agent's responses against a set of
-- example questions. This file creates the two objects the eval run needs:
--   1. AGENT_EVAL_DATASET — a table of example questions + (optional) ground truth.
--   2. AGENT_EVAL_STAGE   — an internal stage that holds the eval config YAML.
--
-- The actual run is kicked off in run_eval.sql (which uploads agent_eval.yaml to
-- the stage and calls EXECUTE_AI_EVALUATION).
USE SCHEMA {{ database }}.{{ schema }};

-- Seed table. One row per example question.
--   input_query  — the user question to send to the agent.
--   ground_truth — a VARIANT with a "ground_truth_output" key describing the
--                  expected answer. Required by the answer_correctness metric;
--                  may be NULL for rows you only score with logical_consistency
--                  (which is reference-free).
CREATE TABLE IF NOT EXISTS {{ database }}.{{ schema }}.AGENT_EVAL_DATASET (
    input_query  VARCHAR,
    ground_truth VARIANT
);

-- Example rows. Replace these with questions representative of your agent.
-- Re-runnable: only inserts when the table is empty.
INSERT INTO {{ database }}.{{ schema }}.AGENT_EVAL_DATASET (input_query, ground_truth)
SELECT column1, PARSE_JSON(column2)
FROM VALUES
    (
        'Which warehouses spent the most credits in the last 30 days?',
        '{"ground_truth_output": "A ranked list of warehouses by CREDITS_USED over the last 30 days from WAREHOUSE_METERING_HISTORY, highest first, with credits converted to currency."}'
    ),
    (
        'Why did our Snowflake spend change recently?',
        '{"ground_truth_output": "An explanation of the recent change in account credit consumption, identifying which services or warehouses drove the change using METERING_DAILY_HISTORY trends."}'
    ),
    (
        'Which users are driving our credit spend?',
        '{"ground_truth_output": "A ranked list of users by attributed compute credits from QUERY_ATTRIBUTION_HISTORY."}'
    )
WHERE NOT EXISTS (SELECT 1 FROM {{ database }}.{{ schema }}.AGENT_EVAL_DATASET);

-- Internal stage that holds the eval config YAML (uploaded by run_eval.sql).
CREATE STAGE IF NOT EXISTS {{ database }}.{{ schema }}.AGENT_EVAL_STAGE
    COMMENT = 'Holds the Cortex Agent evaluation config (agent_eval.yaml).';
