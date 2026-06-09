{{ config(materialized='semantic_view', tags=['semantic_view']) }}

tables (
    WAREHOUSE_LOAD_HISTORY AS {{ ref('stg_account_usage__warehouse_load_history') }} comment='The table contains records of warehouse load activity over time. Each record captures a time-bounded interval for a specific warehouse, including average metrics related to running, queued, provisioning, and blocked workloads.',
    WAREHOUSE_METERING_HISTORY AS {{ ref('stg_account_usage__warehouse_metering_history') }} comment='The table contains records of warehouse credit consumption over time. Each record captures a specific time interval for a given warehouse, detailing the breakdown of credits used across compute and cloud services activity.'
)
facts (
    WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED as AVG_BLOCKED comment='The average number of queries blocked and waiting for a resource lock in the warehouse during the interval.',
    WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD as AVG_QUEUED_LOAD comment='The average number of queries queued due to warehouse resource constraints during the interval.',
    WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING as AVG_QUEUED_PROVISIONING comment='The average number of queries queued due to warehouse provisioning (i.e., the warehouse was being provisioned at the time the query was submitted).',
    WAREHOUSE_LOAD_HISTORY.AVG_RUNNING as AVG_RUNNING comment='The average number of queries running concurrently on the warehouse during the interval.',
    WAREHOUSE_METERING_HISTORY.CREDITS_ATTRIBUTED_COMPUTE_QUERIES as CREDITS_ATTRIBUTED_COMPUTE_QUERIES comment='The number of compute credits attributed to query execution for the warehouse.',
    WAREHOUSE_METERING_HISTORY.CREDITS_USED as CREDITS_USED comment='The total number of compute credits consumed by the warehouse during the metering period.',
    WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES as CREDITS_USED_CLOUD_SERVICES comment='The number of credits consumed by cloud services for the warehouse during the metering period.',
    WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE as CREDITS_USED_COMPUTE comment='The number of compute credits consumed by the warehouse during the metering period.'
)
dimensions (
    WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='The name of the warehouse associated with the load history record.',
    WAREHOUSE_LOAD_HISTORY.START_TIME as START_TIME comment='The start time of the interval during which the warehouse load was measured.',
    WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='The name of the warehouse associated with the metering usage record.',
    WAREHOUSE_METERING_HISTORY.START_TIME as START_TIME comment='The timestamp indicating when the warehouse metering interval began.'
)
metrics (
    WAREHOUSE_LOAD_HISTORY.DISTINCT_LOAD_INTERVALS as COUNT(DISTINCT HASH(start_time, warehouse_name)) comment='Calculates the number of unique load intervals for each warehouse. Use when questions ask about ''unique load intervals'', ''distinct load periods'', or ''how many different load intervals were recorded''. Helps understand the frequency and distribution of load intervals across warehouses.',
    WAREHOUSE_LOAD_HISTORY.TOTAL_LOAD_INTERVALS as COUNT(start_time, warehouse_name) comment='Calculates the total number of load intervals recorded for each warehouse. Use when questions ask about ''total load intervals'', ''count of load periods'', or ''how many load intervals were recorded''. Helps assess the volume of load activity and can be used to understand the frequency of load events across warehouses over a given period.',
    WAREHOUSE_METERING_HISTORY.COUNT_WAREHOUSE_NAME as COUNT(warehouse_name) comment='Calculates the total count of warehouse name entries in the metering history, including duplicates across metering intervals. Use when questions ask about ''COUNT_warehouse_name'', ''COUNT_WAREHOUSE_NAME'', ''how many warehouse records'', or ''total number of warehouse metering entries''. Helps assess the volume of metering records associated with warehouse activity and can be used to understand the frequency of credit consumption events across warehouses over a given period.',
    WAREHOUSE_METERING_HISTORY.DISTINCT_WAREHOUSE_COUNT as COUNT(DISTINCT warehouse_name) comment='Calculates the number of unique warehouses present in the metering history by counting distinct warehouse names. Use when questions ask about ''how many warehouses'', ''number of distinct warehouses'', ''unique warehouse count'', or ''how many different warehouses consumed credits''. Helps understand the breadth of warehouse usage across the environment and assess how many warehouses are actively consuming credits during a given period.',
    WAREHOUSE_METERING_HISTORY.TOTAL_CREDITS_USED as SUM(credits_used) comment='Calculates the sum of all credits used across all warehouses. Use when questions ask about ''total credit spend'', ''total credits consumed'', or ''how much credits were used''. Helps assess the overall credit consumption and aids in budgeting and resource allocation decisions.'
)
ai_verified_queries (
    "For each warehouse, how do credit consumption and workload activity compare over time, and how efficiently is each warehouse converting credits into running queries?" AS (
QUESTION 'For each warehouse, how do credit consumption and workload activity compare over time, and how efficiently is each warehouse converting credits into running queries?'
VERIFIED_AT 1776351632
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  m.start_time,
  m.warehouse_name,
  m.credits_used,
  m.credits_used_compute,
  m.credits_used_cloud_services,
  l.avg_running,
  l.avg_queued_load,
  CASE
    WHEN m.credits_used > 0 THEN (l.avg_running / m.credits_used)
    ELSE 0
  END AS cost_efficiency_index
FROM
  warehouse_metering_history AS m
  LEFT JOIN warehouse_load_history AS l ON l.start_time = m.start_time
  AND l.warehouse_name = m.warehouse_name'),
    "What was our total credit spend for the current month?" AS (
QUESTION 'What was our total credit spend for the current month?'
VERIFIED_AT 1776351841
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  SUM(credits_used) AS total_credits_used
FROM
  warehouse_metering_history
WHERE
  start_time >= DATE_TRUNC(''MONTH'', CURRENT_DATE)
  '),
    "Who were the top 3 spenders yesterday?" AS (
QUESTION 'Who were the top 3 spenders yesterday?'
VERIFIED_AT 1776351917
VERIFIED_BY 'template'
ONBOARDING_QUESTION false
SQL 'SELECT
  warehouse_name,
  SUM(credits_used) AS total_credits_used
FROM
  warehouse_metering_history
WHERE
  start_time >= DATEADD(DAY, -1, DATE_TRUNC(''DAY'', CURRENT_DATE))
  AND start_time < DATE_TRUNC(''DAY'', CURRENT_DATE)
GROUP BY
  warehouse_name
ORDER BY
  total_credits_used DESC NULLS LAST
LIMIT
  3')
)
with extension (CA='{"tables":[{"name":"WAREHOUSE_LOAD_HISTORY","dimensions":[{"name":"WAREHOUSE_NAME","sample_values":["EXAMPLE_WH_1","EXAMPLE_WH_2","EXAMPLE_WH_3"]}],"facts":[{"name":"AVG_BLOCKED","sample_values":["0.000000000"]},{"name":"AVG_QUEUED_LOAD","sample_values":["0.000066667","0.000550000","0.000000000"]},{"name":"AVG_QUEUED_PROVISIONING","sample_values":["0.001390000","0.000403333","0.000000000"]},{"name":"AVG_RUNNING","sample_values":["0.000883333","0.000730000","0.001270000"]}],"metrics":[{"name":"distinct_load_intervals"},{"name":"total_load_intervals"}],"time_dimensions":[{"name":"START_TIME","sample_values":["2026-04-13T20:50:00.000+0000","2026-04-13T16:25:00.000+0000","2026-04-14T01:00:00.000+0000"]}]},{"name":"WAREHOUSE_METERING_HISTORY","dimensions":[{"name":"WAREHOUSE_NAME","sample_values":["EXAMPLE_WH_1","EXAMPLE_WH_3","EXAMPLE_WH_4"]}],"facts":[{"name":"CREDITS_ATTRIBUTED_COMPUTE_QUERIES","sample_values":["0.090167132","0.056307780","0.036104200"]},{"name":"CREDITS_USED","sample_values":["1.137853050","1.302640279","0.339271389"]},{"name":"CREDITS_USED_CLOUD_SERVICES","sample_values":["0.000552222","0.064983890","0.000000000"]},{"name":"CREDITS_USED_COMPUTE","sample_values":["0.026625000","0.229125000","1.125000000"]}],"metrics":[{"name":"COUNT_WAREHOUSE_NAME"},{"name":"DISTINCT_WAREHOUSE_COUNT"},{"name":"total_credits_used"}],"time_dimensions":[{"name":"START_TIME","sample_values":["2026-04-09T07:00:00.000+0000","2026-04-09T08:00:00.000+0000","2026-04-09T06:00:00.000+0000"]}]}]}')
