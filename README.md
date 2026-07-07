# Agent Skills

[![skills.sh](https://skills.sh/b/popovicsandras/agent-skills)](https://skills.sh/popovicsandras/agent-skills)

Cursor agent skills for PR reviews, planning, and architecture documentation.

## Install

1. Run the [skills.sh](https://skills.sh/) installer:

```bash
npx skills@latest add popovicsandras/agent-skills
```

2. Pick the skills you want and which coding agents to install them on.

3. Invoke a skill in chat with `/skill-name` (e.g. `/create-rfc`).

Some skills need extra setup (GitHub token, Atlassian MCP, etc.) — see each skill's `SKILL.md` for details.

## Skills

- **address-gh-reviews** — Address GitHub PR review comments filtered by 👍 reactions.
- **create-action-items** — Turn documents or meeting notes into a structured Markdown action plan.
- **create-jira-items** — Create Jira issues from a structured feedback Markdown file.
- **create-rfc** — Draft an RFC to explore options and build consensus before deciding.
- **create-adr** — Write an Architecture Decision Record after a decision is made.
