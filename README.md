# Snowflake Cortex Agent Template

A production-ready template for building AI-powered data agents on Snowflake using Cortex Agents, Semantic Views, and dbt.

## What This Template Provides

- **Snowflake Cortex Agent** — A conversational AI agent that answers analytical questions using your data
- **Semantic Views via dbt** — Type-safe analytical interfaces that ground the agent's SQL generation
- **Skills System** — Prose-only Markdown playbooks for complex, repeatable agent workflows
- **Evaluation Framework** — Automated quality testing for agent responses
- **CI/CD Pipeline** — GitHub Actions for automated deployment
- **DevContainer** — Reproducible development environment
- **Linting** — SQL, YAML, Markdown, and shell script linting with auto-fix

## Architecture Overview

```mermaid
graph TB
    User[User via Snowflake Intelligence UI] --> Agent[Cortex Agent]
    Agent --> Analyst[Cortex Analyst Tools]
    Agent --> Skills[Skills Stage]
    Analyst --> SV[Semantic Views]
    SV --> Models[dbt Models - Facts & Dims]
    Models --> Sources[Source Data]

    subgraph "Your dbt Project"
        Sources --> Staging[Staging Layer]
        Staging --> Intermediate[Intermediate Layer]
        Intermediate --> Models
        Models --> SV
    end
```

## Getting Started — let an AI assistant set it up for you

This template is built to be configured **by an AI coding assistant**, so you barely have to touch SQL yourself.

1. **Connect your development environment to the LLM of your choice** — Claude Code, Cursor, GitHub Copilot, Windsurf, etc. Any AI coding assistant that can read the repo and run commands works.
2. **Open the project in its DevContainer** (`.devcontainer/`) and wait for it to build. The container ships with dbt, the Snowflake CLI, and linters preinstalled — a reproducible, ready-to-go environment.
3. **Hand it to the AI.** With the container up and your assistant connected, paste the prompt below. It reads the project, fills in `cookiecutter.yml`, provisions Snowflake, and deploys the agent.

Copy and paste this to your AI assistant:

```text
I have a Snowflake Cortex Agent template project. Please read these files in order to understand how to set it up for my project:

1. README.md — overview and structure
2. cookiecutter.yml — project configuration (I need help filling this in)
3. SETUP.md — step-by-step setup guide
4. AGENTS.md — coding conventions and development workflow

Help me configure cookiecutter.yml for my specific project, then walk me through the SETUP.md steps.
```

Prefer to do it by hand? Follow [`SETUP.md`](SETUP.md) directly — it's written to be both human- and AI-readable.

## Project Structure

```text
├── cookiecutter.yml          # YOUR CONFIG — fill this in first
├── SETUP.md                  # Step-by-step setup guide
├── dbt/                      # Data models and semantic views
├── snowflake/                # Agent definition and Snowflake objects
├── cicd/                     # Deployment scripts
├── scripts/                  # Utility scripts
└── docs/                     # Additional documentation
```

## Key Concepts

### Semantic Views

Semantic views are the bridge between your data and the AI agent. They define:

- **What tables and columns exist** (TABLES)
- **How tables relate** (RELATIONSHIPS)
- **Which columns are measures vs. dimensions** (FACTS, DIMENSIONS)
- **Pre-defined calculations** (METRICS)
- **Grounding queries** (AI_VERIFIED_QUERIES)

### Agent Skills

Skills are Markdown documents that guide the agent through complex workflows. They don't execute code — they provide step-by-step instructions the agent follows using its tools.

### Template Variables

Files in `snowflake/` use `{{ variable }}` syntax. The `render_snowflake_templates.py` script resolves these from `cookiecutter.yml` before deployment.

## Documentation

- [`SETUP.md`](SETUP.md) — Complete setup guide (start here)
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — System architecture
- [`AGENTS.md`](AGENTS.md) — Instructions for AI coding assistants
- [`docs/semantic-views-guide.md`](docs/semantic-views-guide.md) — How to write semantic views
- [`docs/authoring-skills.md`](docs/authoring-skills.md) — How to create agent skills
- [`docs/evaluation-guide.md`](docs/evaluation-guide.md) — How to evaluate your agent
- [`docs/customizing-ci-cd.md`](docs/customizing-ci-cd.md) — Adapting CI/CD to your org

## Requirements

- Snowflake Enterprise edition (or higher) with Cortex Agents enabled
- Python 3.12+
- Node.js 20+ (for markdownlint)
- dbt Cloud or dbt Core 1.11+
- Git

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
