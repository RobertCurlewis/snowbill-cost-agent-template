{{ config(materialized='semantic_view', tags=['semantic_view']) }}

tables (
    AUTOMATIC_CLUSTERING_HISTORY AS {{ ref('stg_account_usage__automatic_clustering_history') }} primary key (START_TIME) comment='The table contains records of automatic clustering activity performed on database tables. Each record captures a discrete clustering operation, including the time period of the activity, resource consumption in credits, the volume of data and rows reclustered, and the associated table, schema, and database identifiers.',
    PIPE_USAGE_HISTORY AS {{ ref('stg_account_usage__pipe_usage_history') }} primary key (START_TIME) comment='The table contains records of historical usage activity for data ingestion pipes. Each record captures a time-bounded interval of pipe activity, including credit consumption, billing, and the volume of data and files processed.',
    REPLICATION_USAGE_HISTORY AS {{ ref('stg_account_usage__replication_usage_history') }} comment='The table contains records of database replication activity over time. Each record captures a specific replication event, including the database involved, the duration of the replication, and associated resource consumption in terms of credits used and data transferred.',
    SEARCH_OPTIMIZATION_HISTORY AS {{ ref('stg_account_usage__search_optimization_history') }} comment='The table contains records of search optimization service usage within a Snowflake account. Each record captures a time-bounded period of activity, identifying the specific database objects involved and the computational credits consumed during that interval.'
)
facts (
    AUTOMATIC_CLUSTERING_HISTORY.CREDITS_USED as CREDITS_USED comment='The number of credits consumed by automatic clustering operations.',
    PIPE_USAGE_HISTORY.CREDITS_USED as CREDITS_USED comment='The number of Snowpipe credits consumed during the usage period.',
    REPLICATION_USAGE_HISTORY.CREDITS_USED as CREDITS_USED comment='The number of credits consumed during replication operations.',
    SEARCH_OPTIMIZATION_HISTORY.CREDITS_USED as CREDITS_USED comment='The number of credits consumed by the search optimization service.'
)
dimensions (
    AUTOMATIC_CLUSTERING_HISTORY.DATABASE_NAME as DATABASE_NAME comment='The name of the database associated with the automatic clustering history record.',
    AUTOMATIC_CLUSTERING_HISTORY.SCHEMA_NAME as SCHEMA_NAME comment='The name of the schema associated with the automatic clustering history record.',
    AUTOMATIC_CLUSTERING_HISTORY.TABLE_NAME as TABLE_NAME comment='The name of the table on which automatic clustering was performed.',
    AUTOMATIC_CLUSTERING_HISTORY.START_TIME as START_TIME comment='The start time of the automatic clustering operation.',
    PIPE_USAGE_HISTORY.START_TIME as START_TIME comment='The start time of the pipe usage history interval.',
    REPLICATION_USAGE_HISTORY.DATABASE_NAME as DATABASE_NAME comment='The name of the database being replicated.',
    REPLICATION_USAGE_HISTORY.START_TIME as START_TIME comment='The timestamp indicating when the replication operation began.',
    SEARCH_OPTIMIZATION_HISTORY.DATABASE_NAME as DATABASE_NAME comment='The name of the database associated with the search optimization history record.',
    SEARCH_OPTIMIZATION_HISTORY.SCHEMA_NAME as SCHEMA_NAME comment='The name of the schema associated with the search optimization history record.',
    SEARCH_OPTIMIZATION_HISTORY.TABLE_NAME as TABLE_NAME comment='The name of the table for which search optimization history is recorded.',
    SEARCH_OPTIMIZATION_HISTORY.START_TIME as START_TIME comment='The start time of the search optimization history event.'
)
metrics (
    AUTOMATIC_CLUSTERING_HISTORY.END_DATE as MAX(start_time) comment='Determines the latest start time of automatic clustering operations. Use when questions ask about ''end date'', ''completion of clustering period'', or ''latest clustering activity''. Helps identify the conclusion point of clustering activities, useful for analyzing the duration and frequency of clustering operations.',
    AUTOMATIC_CLUSTERING_HISTORY.START_DATE as MIN(start_time) comment='Determines the earliest start time of automatic clustering operations. Use when questions ask about ''start date'', ''beginning of clustering period'', or ''earliest clustering activity''. Helps identify the initiation point of clustering activities, useful for analyzing the duration and frequency of clustering operations.',
    PIPE_USAGE_HISTORY.TOTAL_CREDITS_USED as SUM(credits_used) comment='Calculates the sum of credits consumed during the usage period for data ingestion pipes. Use when questions ask about ''total credits used'', ''credit consumption'', or ''resource usage for pipes''. Helps analyze the cost and resource utilization of data ingestion activities, track trends over time, and optimize data pipeline efficiency.'
)
ai_verified_queries (
    "What is the 30-day trend for Snowpipe credits?" AS (
QUESTION 'What is the 30-day trend for Snowpipe credits?'
VERIFIED_AT 1776354570
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'WITH daily_credits AS (
  SELECT
    DATE_TRUNC(''DAY'', start_time) AS day,
    SUM(credits_used) AS daily_credits
  FROM
    pipe_usage_history
  GROUP BY
    DATE_TRUNC(''DAY'', start_time)
),
rolling_avg AS (
  SELECT
    day,
    daily_credits,
    AVG(daily_credits) OVER (
      ORDER BY
        day ROWS BETWEEN 29 PRECEDING
        AND CURRENT ROW
    ) AS rolling_avg_30d
  FROM
    daily_credits
)
SELECT
  day,
  daily_credits,
  rolling_avg_30d
FROM
  rolling_avg
WHERE
  day >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY
  day DESC NULLS LAST'),
    "Which tables are generating the most Automatic Clustering overhead?" AS (
QUESTION 'Which tables are generating the most Automatic Clustering overhead?'
VERIFIED_AT 1776354591
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  database_name,
  schema_name,
  table_name,
  MIN(start_time) AS start_date,
  MAX(start_time) AS end_date,
  SUM(credits_used) AS total_credits_used
FROM
  automatic_clustering_history
GROUP BY
  database_name,
  schema_name,
  table_name
ORDER BY
  total_credits_used DESC NULLS LAST'),
    "How many credits are we spending on data replication for Disaster Recovery?" AS (
QUESTION 'How many credits are we spending on data replication for Disaster Recovery?'
VERIFIED_AT 1776354646
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  MIN(start_time) AS start_date,
  MAX(start_time) AS end_date,
  SUM(credits_used) AS total_credits_used
FROM
  replication_usage_history'),
    "Which tables are incurring the highest Search Optimization maintenance costs?" AS (
QUESTION 'Which tables are incurring the highest Search Optimization maintenance costs?'
VERIFIED_AT 1776354755
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  database_name,
  schema_name,
  table_name,
  MIN(start_time) AS start_date,
  MAX(start_time) AS end_date,
  SUM(credits_used) AS total_credits_used
FROM
  search_optimization_history
GROUP BY
  database_name,
  schema_name,
  table_name
ORDER BY
  total_credits_used DESC NULLS LAST'),
    "How many unique databases and tables have undergone automatic clustering?" AS (
QUESTION 'How many unique databases and tables have undergone automatic clustering?'
VERIFIED_AT 1776408551
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  COUNT(database_name) AS count_database_name,
  COUNT(DISTINCT database_name) AS distinct_database_name,
  COUNT(database_name, schema_name, table_name) AS count_database_name_schema_name_table_name,
  COUNT(
    DISTINCT HASH(database_name, schema_name, table_name)
  ) AS distinct_database_name_schema_name_table_name
FROM
  automatic_clustering_history')
)
with extension (CA='{"tables":[{"name":"AUTOMATIC_CLUSTERING_HISTORY","dimensions":[{"name":"DATABASE_NAME","sample_values":["SNOWFLAKE"]},{"name":"SCHEMA_NAME","sample_values":["LOCAL"]},{"name":"TABLE_NAME","sample_values":["AI_OBSERVABILITY_EVENTS"]}],"facts":[{"name":"CREDITS_USED","sample_values":["0.000039444"]}],"metrics":[{"name":"end_date"},{"name":"start_date"}],"time_dimensions":[{"name":"START_TIME","sample_values":["2026-04-09T06:00:00.000+0000"]}]},{"name":"PIPE_USAGE_HISTORY","facts":[{"name":"CREDITS_USED","sample_values":["0.000000000","0.000000004"]}],"metrics":[{"name":"total_credits_used"}],"time_dimensions":[{"name":"START_TIME","sample_values":["2026-04-15T13:46:00.000+0000","2026-04-15T14:06:00.000+0000","2026-04-15T12:56:00.000+0000"]}]},{"name":"REPLICATION_USAGE_HISTORY","dimensions":[{"name":"DATABASE_NAME"}],"facts":[{"name":"CREDITS_USED"}],"time_dimensions":[{"name":"START_TIME"}]},{"name":"SEARCH_OPTIMIZATION_HISTORY","dimensions":[{"name":"DATABASE_NAME"},{"name":"SCHEMA_NAME"},{"name":"TABLE_NAME"}],"facts":[{"name":"CREDITS_USED"}],"time_dimensions":[{"name":"START_TIME"}]}]}')
