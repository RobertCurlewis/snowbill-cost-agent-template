-- Run a Cortex Agent Evaluation on demand and read the scores.
--
-- Prerequisites (one-time):
--   1. Run create_eval_dataset.sql  — creates AGENT_EVAL_DATASET + AGENT_EVAL_STAGE.
--   2. Populate AGENT_EVAL_DATASET   — with questions representative of your agent.
--   3. The deploy role needs task privileges (a Snowflake eval runs as a task):
--        GRANT CREATE TASK ON SCHEMA {{ database }}.{{ schema }} TO ROLE <role>;
--        -- ACCOUNTADMIN must grant the account-level one:
--        GRANT EXECUTE TASK ON ACCOUNT TO ROLE <role>;
--   4. Upload the config to the stage (from the repo root, after rendering):
--        snow stage copy snowflake/rendered/dev/evals/agent_eval.yaml \
--          @{{ database }}.{{ schema }}.AGENT_EVAL_STAGE --overwrite
--
-- run_name must be UNIQUE per run. Bump the suffix on each invocation.
-- The first run uses agent_eval.yaml with its `dataset:` block (imports the
-- table into a dataset). For later runs against the same dataset, remove the
-- `dataset:` block from agent_eval.yaml and re-upload before calling START.
USE SCHEMA {{ database }}.{{ schema }};

-- Start the evaluation.
CALL EXECUTE_AI_EVALUATION(
    'START',
    OBJECT_CONSTRUCT('run_name', 'eval_001'),
    '@{{ database }}.{{ schema }}.AGENT_EVAL_STAGE/agent_eval.yaml'
);

-- Poll until STATUS is COMPLETED (re-run this as needed).
CALL EXECUTE_AI_EVALUATION(
    'STATUS',
    OBJECT_CONSTRUCT('run_name', 'eval_001'),
    '@{{ database }}.{{ schema }}.AGENT_EVAL_STAGE/agent_eval.yaml'
);

-- Read per-question scores once COMPLETED.
--   EVAL_AGG_SCORE — the metric score (1.0 = best).
--   METRIC_STATUS  — per-row judge status; a non-200 code means the judge
--                    failed (e.g. context-window limit), not a bad answer.
SELECT
    LEFT(input, 60)  AS question,
    metric_name,
    eval_agg_score,
    metric_status
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(
    '{{ database }}',
    '{{ schema }}',
    '{{ agent_name }}',
    'CORTEX AGENT',
    'eval_001'
))
ORDER BY input, metric_name;
