{{ config(materialized='semantic_view', tags=['semantic_view']) }}

tables (
    QUERY_HISTORY AS {{ ref('stg_account_usage__query_history') }} comment='The table contains records of queries executed within a database account. Each record represents a single query execution and includes details about the query itself, the user and role that ran it, the warehouse used, and the execution outcome including any errors encountered.'
)
facts (
    QUERY_HISTORY.CACHE_HIT_PERCENT as PERCENTAGE_SCANNED_FROM_CACHE*100,
    QUERY_HISTORY.COMPILATION_SECONDS as COMPILATION_TIME/1000,
    QUERY_HISTORY.PARTITION_SCAN_RATIO as CASE WHEN PARTITIONS_TOTAL > 0 THEN (PARTITIONS_SCANNED / PARTITIONS_TOTAL)
        ELSE 0
    END,
    QUERY_HISTORY.QUEUE_WAIT_SECONDS as QUEUED_OVERLOAD_TIME/1000,
    QUERY_HISTORY.TOTAL_BYTES_SPILLED as (BYTES_SPILLED_TO_LOCAL_STORAGE+BYTES_SPILLED_TO_REMOTE_STORAGE),
    QUERY_HISTORY.TOTAL_SECONDS as TOTAL_ELAPSED_TIME/1000
)
dimensions (
    QUERY_HISTORY.BYTES_SCANNED as BYTES_SCANNED,
    QUERY_HISTORY.DATABASE_NAME as DATABASE_NAME,
    QUERY_HISTORY.EXECUTION_TIME as EXECUTION_TIME,
    QUERY_HISTORY.PARTITIONS_SCANNED as PARTITIONS_SCANNED,
    QUERY_HISTORY.QUERY_ID as QUERY_ID,
    QUERY_HISTORY.QUERY_TAG as QUERY_TAG,
    QUERY_HISTORY.QUERY_TYPE as QUERY_TYPE,
    QUERY_HISTORY.QUEUED_OVERLOAD_TIME as QUEUED_OVERLOAD_TIME,
    QUERY_HISTORY.ROLE_NAME as ROLE_NAME,
    QUERY_HISTORY.SCHEMA_NAME as SCHEMA_NAME,
    QUERY_HISTORY.USER_NAME as USER_NAME,
    QUERY_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME,
    QUERY_HISTORY.WAREHOUSE_SIZE as WAREHOUSE_SIZE,
    QUERY_HISTORY.WAREHOUSE_TYPE as WAREHOUSE_TYPE,
    QUERY_HISTORY.START_TIME as START_TIME
)
metrics (
    QUERY_HISTORY.EXECUTION_TIMESTAMP as MAX(start_time) comment='Calculates the most recent (maximum) start time of query executions. Use when questions ask about ''latest query execution'', ''most recent execution timestamp'', ''last time a query ran'', or ''execution timestamp''. Helps identify the last time a query, user, warehouse, or role was active, and is useful for auditing recent activity or determining the freshness of query execution data.'
)
ai_verified_queries (
    "Show me queries that are slow due to memory issues or disk spilling." AS (
QUESTION 'Show me queries that are slow due to memory issues or disk spilling.'
VERIFIED_AT 1776354106
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  query_id,
  user_name,
  role_name,
  warehouse_name,
  warehouse_size,
  start_time,
  total_seconds,
  execution_time,
  total_bytes_spilled,
  bytes_scanned,
  partition_scan_ratio,
  queue_wait_seconds
FROM
  query_history
WHERE
  total_bytes_spilled > 0
ORDER BY
  total_bytes_spilled DESC NULLS LAST
  '),
    "Which queries performed full table scans yesterday?" AS (
QUESTION 'Which queries performed full table scans yesterday?'
VERIFIED_AT 1776354151
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  query_id,
  user_name,
  role_name,
  warehouse_name,
  warehouse_size,
  start_time,
  total_seconds,
  execution_time,
  bytes_scanned,
  partitions_scanned,
  partition_scan_ratio,
  total_bytes_spilled
FROM
  query_history
WHERE
  start_time >= DATEADD(DAY, -1, DATE_TRUNC(''DAY'', CURRENT_DATE))
  AND start_time < DATE_TRUNC(''DAY'', CURRENT_DATE)
  AND partition_scan_ratio = 1.0
ORDER BY
  bytes_scanned DESC NULLS LAST
  '),
    "Are any of my warehouses currently congested or queuing queries?" AS (
QUESTION 'Are any of my warehouses currently congested or queuing queries?'
VERIFIED_AT 1776354182
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  warehouse_name,
  COUNT(query_id) AS total_queries,
  SUM(queue_wait_seconds) AS total_queue_wait_seconds,
  AVG(queue_wait_seconds) AS avg_queue_wait_seconds,
  MAX(queue_wait_seconds) AS max_queue_wait_seconds,
  SUM(queued_overload_time) AS total_queued_overload_time,
  MAX(start_time) AS latest_query_time
FROM
  query_history
WHERE
  start_time >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
  AND (
    queue_wait_seconds > 0
    OR queued_overload_time > 0
  )
GROUP BY
  warehouse_name
ORDER BY
  total_queue_wait_seconds DESC NULLS LAST
  '),
    "Which roles used the most compute time in the last 7 days?" AS (
QUESTION 'Which roles used the most compute time in the last 7 days?'
VERIFIED_AT 1776354207
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  role_name,
  SUM(total_seconds) AS total_compute_seconds
FROM
  query_history
WHERE
  start_time >= DATEADD(DAY, -7, CURRENT_DATE)
GROUP BY
  role_name
ORDER BY
  total_compute_seconds DESC NULLS LAST
  '),
    "How many unique warehouses, start times, users, queries, and roles are recorded in the query history?" AS (
QUESTION 'How many unique warehouses, start times, users, queries, and roles are recorded in the query history?'
VERIFIED_AT 1776408491
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  COUNT(warehouse_name) AS count_warehouse_name,
  APPROX_COUNT_DISTINCT(warehouse_name) AS distinct_warehouse_name,
  COUNT(start_time) AS count_start_time,
  APPROX_COUNT_DISTINCT(start_time) AS distinct_start_time,
  COUNT(user_name) AS count_user_name,
  APPROX_COUNT_DISTINCT(user_name) AS distinct_user_name,
  COUNT(query_id) AS count_query_id,
  APPROX_COUNT_DISTINCT(query_id) AS distinct_query_id,
  COUNT(role_name) AS count_role_name,
  APPROX_COUNT_DISTINCT(role_name) AS distinct_role_name
FROM
  query_history'),
    "Break down the credit spent for EXAMPLE_SERVICE_USER in the last 3 months" AS (
QUESTION 'Who are the top 5 users by credit spend in the last 3 months?'
VERIFIED_AT 1776409453
VERIFIED_BY 'template'
ONBOARDING_QUESTION true
SQL 'SELECT
    USER_NAME,
    SUM(TOTAL_SECONDS) / 3600 AS TOTAL_COMPUTE_HOURS,
    COUNT(QUERY_ID) AS TOTAL_QUERIES_RUN,
    AVG(PARTITION_SCAN_RATIO) AS AVG_EFFICIENCY
FROM query_history
WHERE START_TIME >= DATEADD(''month'', -3, CURRENT_DATE())
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5'),
    "Break down the credit spent for EXAMPLE_SERVICE_USER in the last 3 months_1" AS (
QUESTION 'What did EXAMPLE_USER spent credits on in the last 3 months?'
VERIFIED_AT 1776410007
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
    QUERY_TYPE,
    WAREHOUSE_NAME,
    SUM(TOTAL_SECONDS) / 3600 AS TOTAL_COMPUTE_HOURS,
    COUNT(QUERY_ID) AS QUERY_COUNT,
    AVG(PARTITION_SCAN_RATIO) AS AVG_SCAN_EFFICIENCY,
    SUM(TOTAL_BYTES_SPILLED) AS TOTAL_DATA_SPILLED
FROM query_history
WHERE USER_NAME = ''EXAMPLE_USER''
  AND START_TIME >= DATEADD(''month'', -3, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 3 DESC')
)
with extension (CA='{"tables":[{"name":"QUERY_HISTORY","dimensions":[{"name":"BYTES_SCANNED"},{"name":"DATABASE_NAME"},{"name":"EXECUTION_TIME"},{"name":"PARTITIONS_SCANNED"},{"name":"QUERY_ID"},{"name":"QUERY_TAG"},{"name":"QUERY_TYPE"},{"name":"QUEUED_OVERLOAD_TIME"},{"name":"ROLE_NAME"},{"name":"SCHEMA_NAME"},{"name":"USER_NAME"},{"name":"WAREHOUSE_NAME"},{"name":"WAREHOUSE_SIZE"},{"name":"WAREHOUSE_TYPE"}],"facts":[{"name":"CACHE_HIT_PERCENT"},{"name":"COMPILATION_SECONDS"},{"name":"PARTITION_SCAN_RATIO"},{"name":"QUEUE_WAIT_SECONDS"},{"name":"TOTAL_BYTES_SPILLED"},{"name":"TOTAL_SECONDS"}],"metrics":[{"name":"EXECUTION_TIMESTAMP"}],"time_dimensions":[{"name":"START_TIME"}]}]}')
