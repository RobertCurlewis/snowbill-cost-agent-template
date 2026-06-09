USE SCHEMA {{ database }}.{{ schema }};
CREATE OR REPLACE AGENT {{ database }}.{{ schema }}.{{ agent_name }}
  COMMENT = '{{ agent_description }}'
  FROM SPECIFICATION
$$
{{ include('agent-specification.yml') }}
$$;

-- Optional: Tag the agent for cost tracking
-- ALTER AGENT IF EXISTS {{ database }}.{{ schema }}.{{ agent_name }}
--   SET TAG {{ database }}.{{ schema }}.COST_TAG = 'agent-cost';
