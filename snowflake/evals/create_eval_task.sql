-- Scheduled task that runs agent evaluation periodically.
-- Adjust the CRON schedule and warehouse as needed.
USE SCHEMA {{ database }}.{{ schema }};

CREATE OR REPLACE TASK {{ database }}.{{ schema }}.AGENT_EVALUATION_TASK
    WAREHOUSE = '{{ warehouse }}'
    SCHEDULE = 'USING CRON 0 6 * * MON UTC'  -- Every Monday at 06:00 UTC
    COMMENT = 'Weekly agent evaluation run'
AS
    SELECT SNOWFLAKE.CORTEX.EXECUTE_AI_EVALUATION(
        'AGENT_EVAL_CONFIG'
    );

-- Task is created in SUSPENDED state — resume when ready:
-- ALTER TASK {{ database }}.{{ schema }}.AGENT_EVALUATION_TASK RESUME;
