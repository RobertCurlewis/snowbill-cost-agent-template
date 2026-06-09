# Customizing CI/CD

## Supported Platforms

This template uses **GitHub Actions** (`.github/workflows/deploy.yml`) for CI/CD.

## Required Secrets / Variables

| Secret | Description |
|--------|-------------|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier |
| `SNOWFLAKE_USER` | Service account username for deployments |
| `SNOWFLAKE_PRIVATE_KEY` | Base64-encoded RSA private key |

| Variable | Description |
|----------|-------------|
| `SNOWFLAKE_DATABASE_DEV` | Dev database name |
| `SNOWFLAKE_DATABASE_PROD` | Prod database name |
| `SNOWFLAKE_ROLE_CICD` | Role for CI/CD deployments |

## Pipeline Flow

1. **Lint** — sqlfluff, yamllint, markdownlint, shellcheck
2. **Render** — Substitute `{{ variables }}` in Snowflake templates
3. **Deploy** — Execute rendered SQL against Snowflake

## Adding dbt to CI/CD

### dbt Core (run in pipeline)

Add a dbt build step before the deploy step:

```yaml
# GitHub Actions example
- name: Install dbt
  run: pip install dbt-core dbt-snowflake
- name: Run dbt
  run: cd dbt && dbt deps && dbt build
  env:
    DBT_PROFILES_DIR: ./ci_profiles
```

### dbt Cloud (triggered externally)

If using dbt Cloud, trigger jobs via API:

```yaml
- name: Trigger dbt Cloud job
  run: |
    curl -X POST "https://cloud.getdbt.com/api/v2/accounts/$ACCOUNT_ID/jobs/$JOB_ID/run/" \
      -H "Authorization: Token $DBT_CLOUD_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"cause": "CI/CD triggered"}'
```

## Adapting to Other CI Systems

The deployment logic lives in `cicd/scripts/`. These scripts work with any CI system
that can:

1. Run Python 3.12+
2. Run bash scripts
3. Set environment variables
4. Provide Snowflake credentials

Simply call:

```bash
python scripts/render_snowflake_templates.py --env $ENV
bash cicd/scripts/deploy.sh
```
