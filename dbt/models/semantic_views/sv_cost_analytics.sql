{{ config(materialized='semantic_view', tags=['semantic_view']) }}

tables (
    METERING_DAILY_HISTORY AS {{ ref('stg_account_usage__metering_daily_history') }} comment='Daily credit consumption by Snowflake service type (warehouse compute, cloud services, and each serverless service). The authoritative source for total account credit spend by category.',
    QUERY_ATTRIBUTION_HISTORY AS {{ ref('stg_account_usage__query_attribution_history') }} comment='Per-query compute-credit attribution. Provides ACTUAL billed credits attributed to each query, user, and warehouse — use this for accurate cost attribution and chargeback (not an estimate).',
    TAG_REFERENCES AS {{ ref('stg_account_usage__tag_references') }} comment='Object tag assignments. Maps tags such as team / cost_center / department to the warehouses and databases they are applied to, for tag-based chargeback.'
)
facts (
    METERING_DAILY_HISTORY.CREDITS_USED as CREDITS_USED comment='Total credits consumed for a service on a day.',
    METERING_DAILY_HISTORY.CREDITS_BILLED as CREDITS_BILLED comment='Credits billed after the cloud-services adjustment.',
    METERING_DAILY_HISTORY.CREDITS_USED_COMPUTE as CREDITS_USED_COMPUTE comment='Compute portion of credits consumed.',
    METERING_DAILY_HISTORY.CREDITS_USED_CLOUD_SERVICES as CREDITS_USED_CLOUD_SERVICES comment='Cloud-services portion of credits consumed.',
    QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE as CREDITS_ATTRIBUTED_COMPUTE comment='Actual compute credits attributed to a query (the basis for accurate user/warehouse/tag chargeback).'
)
dimensions (
    METERING_DAILY_HISTORY.SERVICE_TYPE as SERVICE_TYPE comment='Snowflake service consuming credits (e.g. WAREHOUSE_METERING, AUTO_CLUSTERING, PIPE, SERVERLESS_TASK).',
    METERING_DAILY_HISTORY.USAGE_DATE as USAGE_DATE comment='Date of credit consumption.',
    QUERY_ATTRIBUTION_HISTORY.QUERY_ID as QUERY_ID comment='Identifier of the attributed query.',
    QUERY_ATTRIBUTION_HISTORY.USER_NAME as USER_NAME comment='User responsible for the attributed credits.',
    QUERY_ATTRIBUTION_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse the attributed query ran on.',
    QUERY_ATTRIBUTION_HISTORY.QUERY_TAG as QUERY_TAG comment='Query tag set on the session/query (used for team tagging, e.g. team=ESG).',
    QUERY_ATTRIBUTION_HISTORY.START_TIME as START_TIME comment='When the attributed query started.',
    TAG_REFERENCES.TAG_NAME as TAG_NAME comment='Name of the object tag (e.g. team, cost_center, department).',
    TAG_REFERENCES.TAG_VALUE as TAG_VALUE comment='Value of the object tag (e.g. ESG, Finance).',
    TAG_REFERENCES.OBJECT_NAME as OBJECT_NAME comment='Name of the tagged object (warehouse or database).',
    TAG_REFERENCES.OBJECT_DOMAIN as "DOMAIN" comment='Type of tagged object (WAREHOUSE, DATABASE, etc.).',
    TAG_REFERENCES.OBJECT_DATABASE as OBJECT_DATABASE comment='Database of the tagged object.'
)
metrics (
    METERING_DAILY_HISTORY.TOTAL_CREDITS_USED as SUM(credits_used) comment='Total credits consumed across services. Use for overall and by-service spend.',
    METERING_DAILY_HISTORY.TOTAL_CREDITS_BILLED as SUM(credits_billed) comment='Total billed credits after cloud-services adjustment.',
    QUERY_ATTRIBUTION_HISTORY.TOTAL_ATTRIBUTED_CREDITS as SUM(credits_attributed_compute) comment='Total credits attributed to queries. Use for user / warehouse / tag chargeback.',
    QUERY_ATTRIBUTION_HISTORY.ATTRIBUTED_QUERY_COUNT as COUNT(query_id) comment='Number of attributed queries.'
)
ai_verified_queries (
    "Break down credits by service type for the last 30 days" AS (
QUESTION 'Break down our Snowflake credits by service type for the last 30 days'
VERIFIED_AT 1749470000
VERIFIED_BY 'template'
ONBOARDING_QUESTION true
SQL 'SELECT
  service_type,
  SUM(credits_used) AS total_credits
FROM metering_daily_history
WHERE usage_date >= DATEADD(''day'', -30, CURRENT_DATE())
GROUP BY service_type
ORDER BY total_credits DESC NULLS LAST'),
    "Who are the top users by attributed credits?" AS (
QUESTION 'Who are the top users by attributed credit spend in the last 30 days?'
VERIFIED_AT 1749470000
VERIFIED_BY 'template'
ONBOARDING_QUESTION true
SQL 'SELECT
  user_name,
  SUM(credits_attributed_compute) AS attributed_credits,
  COUNT(query_id) AS query_count
FROM query_attribution_history
WHERE start_time >= DATEADD(''day'', -30, CURRENT_DATE())
GROUP BY user_name
ORDER BY attributed_credits DESC NULLS LAST
LIMIT 20'),
    "What did a specific user spend in the last 30 days?" AS (
QUESTION 'How many credits did a given user consume in the last 30 days?'
VERIFIED_AT 1749470000
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  user_name,
  warehouse_name,
  SUM(credits_attributed_compute) AS attributed_credits,
  COUNT(query_id) AS query_count
FROM query_attribution_history
WHERE start_time >= DATEADD(''day'', -30, CURRENT_DATE())
  AND user_name = ''EXAMPLE_USER''
GROUP BY user_name, warehouse_name
ORDER BY attributed_credits DESC NULLS LAST'),
    "Break down spend by query tag" AS (
QUESTION 'What are our credits grouped by query tag?'
VERIFIED_AT 1749470000
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  query_tag,
  SUM(credits_attributed_compute) AS attributed_credits,
  COUNT(query_id) AS query_count
FROM query_attribution_history
WHERE start_time >= DATEADD(''day'', -30, CURRENT_DATE())
  AND query_tag IS NOT NULL
  AND query_tag <> ''''
GROUP BY query_tag
ORDER BY attributed_credits DESC NULLS LAST'),
    "Chargeback by team using object tags" AS (
QUESTION 'How much is each team spending, using object tags on warehouses?'
VERIFIED_AT 1749470000
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  tr.tag_value AS team,
  SUM(qah.credits_attributed_compute) AS attributed_credits,
  COUNT(qah.query_id) AS query_count
FROM query_attribution_history AS qah
JOIN tag_references AS tr
  ON qah.warehouse_name = tr.object_name
  AND tr.object_domain = ''WAREHOUSE''
WHERE qah.start_time >= DATEADD(''day'', -30, CURRENT_DATE())
GROUP BY tr.tag_value
ORDER BY attributed_credits DESC NULLS LAST')
)
