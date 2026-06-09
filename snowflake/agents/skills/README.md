# Agent Skills

Skills are prose-only Markdown playbooks that give the agent structured workflows for complex or repeatable tasks. They do NOT execute code — they guide the agent's reasoning and tool usage.

## Structure

Each skill is a directory containing a `SKILL.md` file:

```text
skills/
├── health_check/
│   └── SKILL.md
├── weekly_report/
│   └── SKILL.md
└── README.md
```

## Creating a New Skill

1. Create a directory: `skills/<skill_name>/`
2. Add a `SKILL.md` with these sections:
   - **Purpose** — What the skill does
   - **When to Use** — Trigger conditions
   - **Steps** — Ordered steps the agent should follow
   - **Output Format** — How to present results

3. Register the skill in `agent-specification.yml`:

   ```yaml
   - name: "<skill_name>"
     source:
       type: "STAGE"
       path: "@DB.SCHEMA.AGENT_SKILLS_STAGE/skills/<skill_name>"
   ```

4. Add routing in the orchestration instructions:

   ```text
   Use the <skill_name> skill when the user asks about <trigger>.
   ```

## Deployment

Skills are deployed via CI/CD — the `upload_skills.sh` script PUTs them to an internal stage.
