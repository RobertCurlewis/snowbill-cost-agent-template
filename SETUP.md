# Setup Guide — Snowflake Cortex Agent Template

> **For AI Assistants:** Read `cookiecutter.yml` in this project root for the current
> configuration. Ask the user for any values that are still set to defaults/placeholders.
> Then follow this guide step-by-step, verifying each step before proceeding.

---

## Prerequisites

Before starting, ensure you have:

- [ ] A Snowflake account (Enterprise edition or higher for Cortex Agents)
- [ ] A Snowflake user with permissions to create databases, schemas, warehouses, and agents
- [ ] Git installed locally
- [ ] Python 3.12+ installed
- [ ] Node.js 20+ installed (for markdownlint)
- [ ] One of: dbt Cloud account OR dbt Core installed locally

### Optional Prerequisites

- [ ] GitHub or GitLab repository created for this project
- [ ] CI/CD secrets configured (Snowflake credentials)
- [ ] Jira project (if using Jira for task management)

---

## Quick Start (5 minutes)

For those who want the fastest path to a running agent:

1. Fork/clone this repository
2. Fill in `cookiecutter.yml`
3. Run `pip install -r .devcontainer/requirements.txt`
4. Run `cd dbt && dbt deps`
5. Create at least one source, one model, and one semantic view
6. Deploy the agent: `python scripts/render_snowflake_templates.py --env dev && bash cicd/scripts/deploy.sh`

The rest of this guide covers each step in detail.

---

## Step 1: Fork and Configure the Project

### 1.1 Fork or Clone

```bash
# Option A: Fork on GitHub/GitLab, then clone your fork
git clone <your-fork-url>
cd snowflake-cortex-agent-template

# Option B: Clone directly and change remote
git clone <template-url> my-agent-project
cd my-agent-project
git remote set-url origin <your-new-repo-url>
```

### 1.2 Fill in `cookiecutter.yml`

Open `cookiecutter.yml` and fill in ALL required fields:

| Field | Description | Example |
|-------|-------------|---------|
| `project_name` | Kebab-case project name | `sales-analytics-agent` |
| `project_slug` | Snake_case (used in dbt) | `sales_analytics_agent` |
| `business_domain` | Your data domain | `sales`, `marketing`, `ops` |
| `agent_name` | Display name for your agent | `Atlas`, `Nova`, `Scout` |
| `agent_description` | One-line agent purpose | `Sales analytics assistant` |
| `snowflake_account` | Your Snowflake account ID | `myorg-myaccount` |
| `snowflake_database_dev` | Dev database | `DEV_ANALYTICS_DB` |
| `snowflake_database_prod` | Prod database | `PROD_ANALYTICS_DB` |
| `snowflake_schema` | Schema for agent objects | `SALES_AGENT` |
| `snowflake_warehouse` | Warehouse for queries | `ANALYTICS_WH` |
| `snowflake_role_cicd` | CI/CD deployment role | `DEPLOY_ROLE` |
| `snowflake_role_etl` | ETL/transform role | `TRANSFORM_ROLE` |
| `dbt_mode` | `cloud` or `core` | `core` |
| `vcs_provider` | `github` or `gitlab` | `github` |

### 1.3 Rename the dbt Project

In `dbt/dbt_project.yml`, replace `my_cortex_agent` with your `project_slug`:

```yaml
name: 'sales_analytics_agent'  # <-- your project_slug

models:
  sales_analytics_agent:       # <-- must match name above
    ...
```

### Verify Step 1

- [ ] `cookiecutter.yml` has no placeholder values for required fields
- [ ] `dbt/dbt_project.yml` name matches your project_slug

---

## Step 2: Snowflake Environment Setup

### 2.1 Create Database and Schema

Run these in Snowflake (as ACCOUNTADMIN or equivalent):

```sql
-- Development environment
CREATE DATABASE IF NOT EXISTS <snowflake_database_dev>;
CREATE SCHEMA IF NOT EXISTS <snowflake_database_dev>.<snowflake_schema>;

-- Production environment
CREATE DATABASE IF NOT EXISTS <snowflake_database_prod>;
CREATE SCHEMA IF NOT EXISTS <snowflake_database_prod>.<snowflake_schema>;
```

### 2.2 Create Warehouse

```sql
CREATE WAREHOUSE IF NOT EXISTS <snowflake_warehouse>
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for Cortex Agent queries';
```

### 2.3 Create Roles and Grant Permissions

```sql
-- CI/CD Role (deploys objects)
CREATE ROLE IF NOT EXISTS <snowflake_role_cicd>;
GRANT USAGE ON DATABASE <snowflake_database_dev> TO ROLE <snowflake_role_cicd>;
GRANT USAGE ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT CREATE TABLE ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT CREATE VIEW ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT CREATE STAGE ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT CREATE SEMANTIC VIEW ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT CREATE CORTEX AGENT ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_cicd>;
GRANT USAGE ON WAREHOUSE <snowflake_warehouse> TO ROLE <snowflake_role_cicd>;

-- ETL Role (runs transformations)
CREATE ROLE IF NOT EXISTS <snowflake_role_etl>;
GRANT USAGE ON DATABASE <snowflake_database_dev> TO ROLE <snowflake_role_etl>;
GRANT ALL ON SCHEMA <snowflake_database_dev>.<snowflake_schema> TO ROLE <snowflake_role_etl>;
GRANT USAGE ON WAREHOUSE <snowflake_warehouse> TO ROLE <snowflake_role_etl>;

-- Repeat grants for production database as needed
```

### 2.4 Configure Local Snowflake Connection

```bash
# Using Snowflake CLI
snow connection add \
    --connection-name dev \
    --account <snowflake_account> \
    --user <your_username> \
    --authenticator externalbrowser \
    --database <snowflake_database_dev> \
    --schema <snowflake_schema> \
    --warehouse <snowflake_warehouse> \
    --role <snowflake_role_cicd>
```

### Verify Step 2

```bash
# Test the connection
snow sql --query "SELECT CURRENT_ACCOUNT(), CURRENT_ROLE(), CURRENT_DATABASE()"
```

---

## Step 3: dbt Configuration

### IF dbt_mode == "core"

#### 3.1 Create profiles.yml

Create `~/.dbt/profiles.yml`:

```yaml
default:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <snowflake_account>
      user: <your_username>
      authenticator: externalbrowser
      database: <snowflake_database_dev>
      schema: <snowflake_schema>
      warehouse: <snowflake_warehouse>
      role: <snowflake_role_etl>
      threads: 8
    prod:
      type: snowflake
      account: <snowflake_account>
      user: <cicd_user>
      private_key_path: /path/to/key.p8
      database: <snowflake_database_prod>
      schema: <snowflake_schema>
      warehouse: <snowflake_warehouse>
      role: <snowflake_role_etl>
      threads: 8
```

#### 3.2 Install Dependencies

```bash
cd dbt
dbt deps
```

#### 3.3 Test Connection

```bash
dbt debug
```

### IF dbt_mode == "cloud"

#### 3.1 Create dbt Cloud Project

1. Log in to dbt Cloud
2. Create a new project connected to your repository
3. Configure the Snowflake connection (account, warehouse, database, role)
4. Note the project ID

#### 3.2 Update Configuration

In `dbt/dbt_project.yml`, uncomment and set:

```yaml
dbt-cloud:
  project-id: <your_project_id>
```

#### 3.3 Create Jobs

Create two jobs in dbt Cloud:

- **Seed job**: `dbt seed` (run manually or on schedule)
- **Build job**: `dbt build` (triggered on PR merge or on schedule)

### Verify Step 3

```bash
# dbt Core:
cd dbt && dbt debug && dbt deps

# dbt Cloud:
# Verify connection in dbt Cloud UI → Project Settings → Connection
```

---

## Step 4: Create Your Data Models

### 4.1 Define Sources

Edit `dbt/models/sources.yml` to point to your actual data:

```yaml
version: 2

sources:
  - name: my_sales_data
    description: "Sales transactions from our data warehouse"
    database: "{{ 'PROD_DB' if (target.name != 'dev' or var('use_prod_sources_in_dev', false)) else 'DEV_DB' }}"
    schema: SALES_RAW
    tables:
      - name: ORDERS
        description: "Raw order records"
        columns:
          - name: ORDER_ID
            description: "Unique order identifier"
            tests:
              - not_null
              - unique
```

### 4.2 Create Staging Model

Create `dbt/models/staging/stg_orders.sql`:

```sql
SELECT
    order_id,
    customer_id,
    order_date::DATE AS order_date,
    status,
    total_amount::DECIMAL(12,2) AS total_amount,
    item_count,
    channel
FROM {{ source('my_sales_data', 'ORDERS') }}
```

### 4.3 Create Fact Model

Create `dbt/models/marts/fct_orders.sql`:

```sql
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.total_amount,
    o.item_count,
    o.channel
FROM {{ ref('stg_orders') }} AS o
WHERE o.status = 'completed'
```

### 4.4 Document Your Models

Create `dbt/models/staging/schema.yml` and `dbt/models/marts/schema.yml` with descriptions for every model and column.

### 4.5 Run dbt

```bash
cd dbt
dbt run
dbt test
```

### Verify Step 4

- [ ] `dbt run` completes without errors
- [ ] `dbt test` passes (or warns on upstream data quality)
- [ ] Tables exist in Snowflake: `SHOW TABLES IN SCHEMA <database>.<schema>`

---

## Step 5: Create Your Semantic View

### 5.1 Create the Semantic View SQL

Create `dbt/models/semantic_views/sv_orders.sql`:

```sql
{{ config(materialized='semantic_view') }}

TABLES (
    orders AS (
        SELECT
            ORDER_ID,
            CUSTOMER_ID,
            ORDER_DATE,
            STATUS,
            TOTAL_AMOUNT,
            ITEM_COUNT,
            CHANNEL
        FROM {{ ref('fct_orders') }}
    ) PRIMARY KEY (ORDER_ID)
      COMMENT = 'Completed orders with amount and channel'
)

FACTS (
    orders.TOTAL_AMOUNT COMMENT = 'Order total in local currency',
    orders.ITEM_COUNT COMMENT = 'Number of items in the order'
)

DIMENSIONS (
    orders.ORDER_ID COMMENT = 'Unique order identifier',
    orders.CUSTOMER_ID COMMENT = 'Customer who placed the order',
    orders.ORDER_DATE COMMENT = 'Date the order was placed',
    orders.STATUS COMMENT = 'Order status (completed)',
    orders.CHANNEL COMMENT = 'Sales channel (web, mobile, in-store)'
        WITH SYNONYMS ('platform', 'source')
)

METRICS (
    TOTAL_REVENUE AS SUM(orders.TOTAL_AMOUNT)
        COMMENT = 'Sum of all order amounts',
    ORDER_COUNT AS COUNT(orders.ORDER_ID)
        COMMENT = 'Total number of orders',
    AVG_ORDER_VALUE AS AVG(orders.TOTAL_AMOUNT)
        COMMENT = 'Average order value (revenue / orders)'
)

COMMENT = 'Order analytics: revenue, volumes, and channel performance'

AI_SQL_GENERATION $$
When querying revenue, always use SUM(TOTAL_AMOUNT).
Round currency values to 2 decimal places.
Default time period is the last 30 days if not specified.
$$

AI_QUESTION_CATEGORIZATION $$
This view answers questions about:
- Order volumes and trends
- Revenue and average order value
- Channel/platform performance
- Customer order patterns

It does NOT answer questions about: products, inventory, marketing campaigns.
$$

AI_VERIFIED_QUERIES (
    QUERY (
        QUESTION = 'What was total revenue last week?'
        SQL = 'SELECT SUM(TOTAL_AMOUNT) AS total_revenue
               FROM __orders AS orders
               WHERE orders.ORDER_DATE >= DATEADD(week, -1, CURRENT_DATE())
                 AND orders.ORDER_DATE < CURRENT_DATE()'
        VERIFIED_AT = 2024-01-01
        VERIFIED_BY = 'setup'
    )
)
```

### 5.2 Create Instruction Macro

Create `dbt/macros/semantic_view_instructions/sv_orders.sql`:

```sql
{% macro sv_orders_sql_generation() %}
When querying revenue, always use SUM(TOTAL_AMOUNT).
Round currency values to 2 decimal places.
Default time period is the last 30 days if not specified.
Group by ORDER_DATE for time series, by CHANNEL for breakdowns.
{% endmacro %}

{% macro sv_orders_question_categorization() %}
This view answers questions about:
- Order volumes and trends over time
- Revenue metrics (total, average, by channel)
- Channel performance comparisons

It does NOT cover: product details, inventory, customer demographics, marketing.
Redirect product questions to the product analyst tool.
{% endmacro %}
```

### 5.3 Deploy the Semantic View

```bash
cd dbt
dbt run --select tag:semantic_view
```

### Verify Step 5

```sql
-- Check the semantic view exists
SHOW SEMANTIC VIEWS IN SCHEMA <database>.<schema>;

-- Test it with Cortex Analyst
SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-sonnet-4-5',
    'Given the semantic view <database>.<schema>.SV_ORDERS, write SQL for: total revenue last week'
);
```

---

## Step 6: Configure Your Agent

### 6.1 Customize the System Prompt

Edit `snowflake/agents/system-prompt.md`:

- Replace all `{{ PLACEHOLDER }}` values with your agent's specifics
- Define your agent's identity, scope, and domain knowledge
- Add your glossary of business terms
- Set locale, currency, and timezone

### 6.2 Configure the Agent Specification

Edit `snowflake/agents/agent-specification.yml`:

- Add a `tool_spec` entry for each semantic view
- Add corresponding `tool_resources` entries mapping tools to semantic views
- Update orchestration instructions with routing rules
- Add skills as needed

### 6.3 Deploy the Agent

```bash
# Render templates
python scripts/render_snowflake_templates.py --env dev

# Deploy
bash cicd/scripts/deploy.sh
```

### 6.4 Test the Agent

```sql
-- In Snowflake, test the agent directly
SELECT SNOWFLAKE.CORTEX.AGENT(
    '<database>.<schema>.<AGENT_NAME>',
    'What was total revenue last week?'
);
```

Or access via **Snowflake Intelligence UI** (recommended).

### Verify Step 6

- [ ] Agent created successfully (no errors)
- [ ] Agent responds to basic questions
- [ ] Agent correctly routes to the right semantic view
- [ ] Agent refuses out-of-scope questions

---

## Step 7: Set Up CI/CD

### IF vcs_provider == "github"

1. **Add secrets** to your GitHub repository settings:
   - `SNOWFLAKE_ACCOUNT` — Your account identifier
   - `SNOWFLAKE_USER` — CI/CD user name
   - `SNOWFLAKE_PRIVATE_KEY` — Base64-encoded private key

2. **Add variables** to environments (Settings → Environments):
   - Environment `dev`:
     - `SNOWFLAKE_DATABASE_DEV` — Dev database name
     - `SNOWFLAKE_ROLE_CICD` — CI/CD role
   - Environment `production`:
     - `SNOWFLAKE_DATABASE_PROD` — Prod database name
     - `SNOWFLAKE_ROLE_CICD` — CI/CD role

3. **The workflow** at `.github/workflows/deploy.yml` is already configured.

4. **Test**: Create a PR and verify the lint + deploy-dev jobs pass.

### IF vcs_provider == "gitlab"

1. **Add CI/CD variables** (Settings → CI/CD → Variables):
   - `SNOWFLAKE_ACCOUNT`
   - `SNOWFLAKE_USER`
   - `SNOWFLAKE_PRIVATE_KEY` (masked)
   - `SNOWFLAKE_DATABASE_DEV`
   - `SNOWFLAKE_DATABASE_PROD`

2. **The pipeline** at `.gitlab-ci.yml` is already configured.

3. **Test**: Create an MR and verify the pipeline passes.

### Verify Step 7

- [ ] CI pipeline runs lint on PR/MR
- [ ] CI pipeline deploys to dev on PR/MR
- [ ] CI pipeline deploys to prod on tag (or main merge)

---

## Step 8: Set Up Evaluation (Optional)

### 8.1 Create Evaluation Queries

Create `dbt/seeds/agent_eval_queries.csv`:

```csv
INPUT_QUERY,GROUND_TRUTH_OUTPUT
"What was total revenue last week?","{""answer"": ""Total revenue last week was $X""}"
"How many orders did we process yesterday?","{""answer"": ""We processed N orders yesterday""}"
```

### 8.2 Seed and Create Dataset

```bash
cd dbt && dbt seed --select agent_eval_queries
```

Then deploy the eval SQL:

```bash
python scripts/render_snowflake_templates.py --env dev
snow sql --filename snowflake/rendered/dev/evals/create_eval_dataset.sql
```

### 8.3 Run Evaluation

```sql
SELECT SNOWFLAKE.CORTEX.EXECUTE_AI_EVALUATION('AGENT_EVAL_CONFIG');
```

---

## Step 9: Local Development Workflow

### Daily Development Loop

```bash
# 1. Create a feature branch
git checkout -b feature/add-product-semantic-view

# 2. Write your dbt models
# Edit files in dbt/models/

# 3. Run and test
cd dbt && dbt run && dbt test

# 4. Deploy to dev Snowflake
cd .. && python scripts/render_snowflake_templates.py --env dev
bash cicd/scripts/deploy.sh  # or deploy specific files manually

# 5. Test the agent in Snowflake Intelligence UI

# 6. Commit and push
git add . && git commit -m "Add product semantic view"
git push -u origin feature/add-product-semantic-view

# 7. Open PR/MR for review
```

### Adding a New Data Domain

1. Add source to `dbt/models/sources.yml`
2. Create staging model: `dbt/models/staging/stg_<source>.sql`
3. Create fact/dim model: `dbt/models/marts/fct_<domain>.sql`
4. Create semantic view: `dbt/models/semantic_views/sv_<domain>.sql`
5. Create instruction macro: `dbt/macros/semantic_view_instructions/sv_<domain>.sql`
6. Add tool to `snowflake/agents/agent-specification.yml`
7. Update orchestration instructions with routing rules
8. Add verified queries to the semantic view
9. Add eval queries to `dbt/seeds/agent_eval_queries.csv`
10. Test end-to-end

---

## Appendix A: Project Structure Reference

```text
your-agent-project/
├── cookiecutter.yml              # Project configuration (fill this in first)
├── SETUP.md                      # This file
├── README.md                     # Project overview
├── AGENTS.md                     # AI coding assistant instructions
├── ARCHITECTURE.md               # System architecture diagram
│
├── dbt/                          # Data transformation layer
│   ├── dbt_project.yml           # dbt project config
│   ├── packages.yml              # dbt packages (semantic_view, utils)
│   ├── models/
│   │   ├── sources.yml           # Source definitions
│   │   ├── staging/              # stg_* models (1:1 with sources)
│   │   ├── intermediate/         # int_* models (joins, logic)
│   │   ├── marts/                # fct_*/dim_* models (final tables)
│   │   └── semantic_views/       # sv_* semantic views (public interface)
│   ├── macros/
│   │   └── semantic_view_instructions/
│   └── seeds/                    # CSV reference data + eval queries
│
├── snowflake/                    # Snowflake object definitions (templated)
│   ├── agents/                   # Agent SQL, spec, system prompt, skills
│   ├── evals/                    # Evaluation framework SQL
│   ├── stages/                   # Internal stages
│   └── tags/                     # Cost tracking tags
│
├── scripts/                      # Utility scripts
│   ├── render_snowflake_templates.py
│   └── lint.sh
│
├── cicd/scripts/                 # CI/CD deployment scripts
│   ├── lib.sh
│   ├── deploy.sh
│   └── upload_skills.sh
│
├── .github/workflows/            # GitHub Actions (delete if using GitLab)
├── .gitlab-ci.yml                # GitLab CI (delete if using GitHub)
├── .devcontainer/                # Dev container for reproducible env
├── .githooks/                    # Git hooks (pre-push lint)
├── docs/                         # Additional documentation
└── examples/                     # Worked examples (optional reference)
```

## Appendix B: Troubleshooting

| Problem | Solution |
|---------|----------|
| `dbt deps` fails | Check internet access and `packages.yml` syntax |
| Template render fails with "variable not found" | Ensure `cookiecutter.yml` has all required fields |
| Agent creation fails | Check role has `CREATE CORTEX AGENT` privilege |
| Semantic view won't create | Check `dbt_semantic_view` package is installed (`dbt deps`) |
| Agent gives wrong answers | Add more verified queries; check AI_SQL_GENERATION instructions |
| CI/CD fails to authenticate | Verify secrets are base64-encoded correctly |
| Linting fails on SQL | Run `sqlfluff fix dbt/models/` to auto-fix |

## Appendix C: Useful Commands

```bash
# dbt
dbt deps                          # Install packages
dbt run                           # Build all models
dbt run --select tag:semantic_view # Build semantic views only
dbt test                          # Run tests
dbt docs generate && dbt docs serve # Generate and view documentation

# Snowflake CLI
snow sql --query "SHOW AGENTS IN SCHEMA db.schema"
snow sql --query "SHOW SEMANTIC VIEWS IN SCHEMA db.schema"
snow stage list-files @db.schema.AGENT_SKILLS_STAGE

# Linting
scripts/lint.sh --local           # Run all linters (skip missing)
sqlfluff fix dbt/models/          # Auto-fix SQL issues

# Template rendering
python scripts/render_snowflake_templates.py --env dev
python scripts/render_snowflake_templates.py --env prod
```
