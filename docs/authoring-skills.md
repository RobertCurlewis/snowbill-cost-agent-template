# Authoring Agent Skills

## What Are Skills?

Skills are prose-only Markdown documents that give your Cortex Agent structured
workflows for complex or repeatable analytical tasks. They guide the agent's
reasoning and tool usage without executing code.

## When to Create a Skill

Create a skill when:

- A task requires multiple tool calls in a specific sequence
- Users repeatedly ask for the same complex analysis
- The output needs a specific format or structure
- Domain expertise is needed to interpret results correctly

## Skill Structure

Every skill needs a `SKILL.md` file with these sections:

```markdown
# Skill Name

## Purpose
What does this skill accomplish?

## When to Use
What triggers this skill? (user phrases, conditions)

## Steps
1. First step (which tool to call, what to look for)
2. Second step (how to interpret results)
3. Third step (how to combine with other data)
...

## Output Format
How should the agent present results?

## Caveats
What limitations or edge cases should the agent flag?
```

## Deployment

1. Create `snowflake/agents/skills/<skill_name>/SKILL.md`
2. Register in `agent-specification.yml`:

   ```yaml
   skills:
     - name: "<skill_name>"
       source:
         type: "STAGE"
         path: "@DB.SCHEMA.AGENT_SKILLS_STAGE/skills/<skill_name>"
   ```

3. Add routing in orchestration instructions
4. Deploy via CI/CD (or manually: `snow stage copy`)

## Example: Weekly Report Skill

```markdown
# Weekly Report

## Purpose
Generate a structured weekly performance summary.

## When to Use
User asks for "weekly report", "weekly summary", or "how did we do last week".

## Steps
1. Query total revenue and order count for last 7 days vs. prior 7 days
2. Identify top 3 growth channels and top 3 declining channels
3. Flag any metric that moved more than 10% week-over-week
4. Check for data freshness issues before reporting

## Output Format
| Metric | This Week | Last Week | Change |
|--------|-----------|-----------|--------|
| Revenue | ... | ... | +X% |
| Orders | ... | ... | +X% |

## Caveats
- Only includes completed orders
- Partial weeks may skew comparisons
```
