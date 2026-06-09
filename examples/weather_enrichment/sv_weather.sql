-- Semantic view for weather data.
-- Copy to: dbt/models/semantic_views/sv_weather.sql

{{ config(materialized='semantic_view') }}

TABLES (
    weather AS (
        SELECT
            STORE_ID,
            OBSERVATION_DATE,
            MAX_TEMP_C,
            MIN_TEMP_C,
            PRECIPITATION_MM,
            WIND_SPEED_MPH,
            WEATHER_DESCRIPTION
        FROM {{ ref('fct_store_weather') }}
    ) PRIMARY KEY (STORE_ID, OBSERVATION_DATE)
      COMMENT = 'Daily weather observations by store location'
)

FACTS (
    weather.MAX_TEMP_C COMMENT = 'Maximum temperature in Celsius',
    weather.MIN_TEMP_C COMMENT = 'Minimum temperature in Celsius',
    weather.PRECIPITATION_MM COMMENT = 'Total precipitation in millimetres',
    weather.WIND_SPEED_MPH COMMENT = 'Average wind speed in mph'
)

DIMENSIONS (
    weather.STORE_ID COMMENT = 'Store identifier',
    weather.OBSERVATION_DATE COMMENT = 'Date of weather observation',
    weather.WEATHER_DESCRIPTION COMMENT = 'Human-readable weather summary (sunny, rainy, etc.)'
        WITH SYNONYMS ('conditions', 'weather_type')
)

METRICS (
    AVG_MAX_TEMP AS AVG(weather.MAX_TEMP_C)
        COMMENT = 'Average maximum temperature across stores/dates',
    TOTAL_RAINFALL AS SUM(weather.PRECIPITATION_MM)
        COMMENT = 'Total precipitation across stores/dates',
    RAINY_DAYS AS COUNT_IF(weather.PRECIPITATION_MM > 0.2, weather.OBSERVATION_DATE)
        COMMENT = 'Number of days with measurable rainfall (>0.2mm)'
)

COMMENT = 'Weather data by store location — use alongside order data for demand-weather analysis'

AI_SQL_GENERATION $$
Round temperatures to 1 decimal place.
Round precipitation to 1 decimal place.
Default to the last 30 days if no date range specified.
Use OBSERVATION_DATE for time filtering.
$$

AI_QUESTION_CATEGORIZATION $$
This view answers questions about:
- Historical weather by store location
- Temperature, rainfall, and wind patterns
- Weather conditions on specific dates

It does NOT answer: order volumes, revenue, or any commercial metrics.
Use alongside the orders tool to correlate weather with demand.
$$
