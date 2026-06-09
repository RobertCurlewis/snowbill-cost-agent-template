USE SCHEMA {{ database }}.{{ schema }};
CREATE STAGE IF NOT EXISTS {{ database }}.{{ schema }}.AGENT_SKILLS_STAGE
    COMMENT = 'Internal stage for agent skill markdown files'
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
