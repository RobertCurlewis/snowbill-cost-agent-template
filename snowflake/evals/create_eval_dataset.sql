-- Create an evaluation dataset from a seed table.
-- Requires: a dbt seed with columns INPUT_QUERY and GROUND_TRUTH_OUTPUT
USE SCHEMA {{ database }}.{{ schema }};

SELECT SYSTEM$CREATE_EVALUATION_DATASET(
    '{{ database }}.{{ schema }}.AGENT_EVAL_DATASET',
    'SNOWFLAKE.ML.QUESTION_ANSWER',
    '{{ database }}.{{ schema }}.AGENT_EVAL_QUERIES'  -- The seed table
);
