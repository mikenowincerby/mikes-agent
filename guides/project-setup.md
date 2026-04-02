# Creating Project-Specific Agents

The project CLAUDE.md is the single source of truth for agent behavior. It contains identity, domain knowledge, and universal rules.

## How to Create a New Project Agent

1. **Create the project directory:**
   ```bash
   mkdir -p ~/my-project
   ```

2. **Create a CLAUDE.md inside it** with these sections:

```markdown
# [Agent Name]

You are [role description] for [user name] ([title] at Cerby).
Your domain: [what this agent specializes in]

## Cold Start — Read Before Every Response
1. Read `briefings/briefings.md` — session knowledge index
2. Read `briefings/active-work.md` — current tasks and progress
3. This file (`CLAUDE.md`) — repo structure and workflow

## What You Own
- [Capability 1 — how it works, key files/APIs]
- [Capability 2]

## What You Do NOT Own
- [Out-of-scope area 1 — which agent handles it]

## Key Data Sources
| Name | ID / Endpoint |
|------|--------------|
| [Source 1] | [ID or URL] |

## Key Files
| File | Purpose |
|------|---------|
| [file.py] | [What it does] |

## Approval Required (WAIT for user confirmation)
- [Irreversible action 1]
- Any action that modifies production data

## No Approval Needed (Just do it)
- Reading any file, spreadsheet, or data source
- Running analysis scripts
- Creating/editing files in the project directory

## Domain-Specific Rules
- [Rule 1 specific to this project]
```

3. **Run bootstrap:** `./bootstrap.sh` to set up auth and the global CLAUDE.md shim.

## Project CLAUDE.md Best Practices

- **Be specific with commands.** List exact executable commands with flags.
- **Show code examples, not descriptions.** One real function demonstrating your conventions replaces paragraphs of prose.
- **Define boundaries explicitly.** List what this agent must never do alongside what it can do.
- **Keep files under 500 lines.** Long files dilute attention.
- **Include verification criteria.** Tell the agent HOW to verify its work.
- **Prune regularly.** For each line, ask: "Would removing this cause the agent to make mistakes?" If not, cut it.
