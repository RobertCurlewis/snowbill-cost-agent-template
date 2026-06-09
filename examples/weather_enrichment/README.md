# Example: Weather Enrichment (Cross-Domain Join)

This example shows how to bring external/enrichment data into your agent by
joining it with your primary domain data.

## Pattern

1. Source the external data (weather API, third-party feed, etc.)
2. Create a bridge/mapping table (e.g., store → weather station)
3. Join in intermediate layer
4. Expose via its own semantic view OR enrich an existing fact table

## Files

- `stg_weather.sql` — Staging model for weather data
- `fct_store_weather.sql` — Store-level daily weather fact
- `sv_weather.sql` — Standalone weather semantic view
- `bridge_seed.csv` — Example bridge table (store → weather station)

## Multi-Tool Pattern

The agent can combine weather data with order data by calling both tools:

- "Did rain affect sales last week?" → weather_analyst + orders_analyst
