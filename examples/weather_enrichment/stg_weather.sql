-- Staging model for daily weather observations.
-- Copy to: dbt/models/staging/stg_weather.sql

SELECT
    observation_date::DATE AS observation_date,
    station_id::VARCHAR AS station_id,
    max_temp_c::DECIMAL(5, 1) AS max_temp_c,
    min_temp_c::DECIMAL(5, 1) AS min_temp_c,
    precipitation_mm::DECIMAL(6, 1) AS precipitation_mm,
    wind_speed_mph::DECIMAL(5, 1) AS wind_speed_mph,
    weather_description::VARCHAR AS weather_description
FROM {{ source('weather', 'DAILY_OBSERVATIONS') }}
