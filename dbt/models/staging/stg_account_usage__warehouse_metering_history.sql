-- 1:1 wrapper over SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY.
-- Adopters with a materialized copy: repoint the FROM below to your table.
-- The semantic views read this wrapper, so no semantic-view changes are needed.
SELECT * FROM {{ source('account_usage', 'WAREHOUSE_METERING_HISTORY') }}
