-- Optional: Create a cost tracking tag for the agent
USE SCHEMA {{ database }}.{{ schema }};
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.AGENT_COST_TAG
    COMMENT = 'Tag for tracking agent-related compute costs';
