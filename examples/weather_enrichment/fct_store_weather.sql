-- Fact model: Daily weather per store (joined via bridge table).
-- Copy to: dbt/models/marts/fct_store_weather.sql

WITH bridge AS (
    SELECT
        store_id,
        station_id
    FROM {{ ref('store_weather_bridge') }}
)

SELECT
    b.store_id,
    w.observation_date,
    w.max_temp_c,
    w.min_temp_c,
    w.precipitation_mm,
    w.wind_speed_mph,
    w.weather_description
FROM {{ ref('stg_weather') }} AS w
INNER JOIN bridge AS b
    ON w.station_id = b.station_id
