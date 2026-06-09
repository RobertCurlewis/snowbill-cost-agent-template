# Architecture

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        UI[Snowflake Intelligence UI]
    end

    subgraph "Agent Layer"
        Agent[Cortex Agent]
        SP[System Prompt]
        Skills[Skills - Markdown Playbooks]
        Agent --> SP
        Agent --> Skills
    end

    subgraph "Analytics Layer"
        AT1[Analyst Tool 1]
        AT2[Analyst Tool 2]
        ATn[Analyst Tool N]
        Chart[data_to_chart]
    end

    subgraph "Semantic Layer"
        SV1[Semantic View 1]
        SV2[Semantic View 2]
        SVn[Semantic View N]
    end

    subgraph "Data Layer - dbt"
        FCT[Fact Tables]
        DIM[Dimension Tables]
        INT[Intermediate Models]
        STG[Staging Models]
    end

    subgraph "Source Data"
        S1[Source 1]
        S2[Source 2]
        Sn[Source N]
    end

    UI --> Agent
    Agent --> AT1
    Agent --> AT2
    Agent --> ATn
    Agent --> Chart
    AT1 --> SV1
    AT2 --> SV2
    ATn --> SVn
    SV1 --> FCT
    SV1 --> DIM
    SV2 --> FCT
    SVn --> FCT
    FCT --> INT
    DIM --> INT
    INT --> STG
    STG --> S1
    STG --> S2
    STG --> Sn
```

## Data Flow

```mermaid
flowchart LR
    Sources["Source Tables\n(raw data)"]
    Staging["Staging\n(stg_*)"]
    Intermediate["Intermediate\n(int_*)"]
    Marts["Marts\n(fct_*, dim_*)"]
    SemanticViews["Semantic Views\n(sv_*)"]
    Agent["Cortex Agent"]

    Sources --> Staging --> Intermediate --> Marts --> SemanticViews --> Agent
```

## Deployment Pipeline

```mermaid
flowchart LR
    Code["Code Change"] --> PR["PR / MR"]
    PR --> Lint["Lint\n(sqlfluff, yamllint, etc.)"]
    Lint --> dbt["dbt build\n(models + tests)"]
    dbt --> Render["Render Templates\n({{ vars }})"]
    Render --> Deploy["Deploy to Snowflake\n(tags, stages, agent, skills)"]
    Deploy --> Eval["Run Evaluation\n(optional)"]
```

## Component Details

### Cortex Agent

The agent is a Snowflake object created via `CREATE OR REPLACE AGENT`. It orchestrates:

- **Cortex Analyst tools** — Text-to-SQL against semantic views
- **Skills** — Markdown playbooks for complex workflows
- **data_to_chart** — Visualization from query results

### Semantic Views

Semantic views are the analytical contract between raw data and the AI agent. They:

- Define what data is available (tables, columns)
- Specify relationships (joins, foreign keys)
- Classify columns as facts or dimensions
- Pre-define metrics (aggregations)
- Provide verified queries for grounding

### dbt Project

The dbt project transforms raw source data into clean, documented analytical tables:

- **Staging** — 1:1 source mapping, type casting, renaming
- **Intermediate** — Joins, business logic, deduplication
- **Marts** — Final analytical tables (facts and dimensions)
- **Semantic Views** — AI-readable analytical interface

### Skills

Skills are Markdown documents deployed to a Snowflake internal stage. They guide the agent through multi-step analytical workflows without executing code.

### CI/CD

The pipeline handles:

1. Linting (SQL, YAML, Markdown, Shell)
2. Template rendering (variable substitution)
3. Deployment (tags → stages → agent → skills → eval)
