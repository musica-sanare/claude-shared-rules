# Project instructions for Claude Code

## Product
The owner's shared Claude Code rules, loaded in every project through `~/.claude/rules/shared/`, with their docs, templates, hooks, optional rules, and task prompts.

## Read first
- `docs/en/README.md` (docs index)
- `rules/overrides.md`

## Project principles
- Stay project-agnostic. Rules, docs, templates, hooks, and prompts never name a specific project or repository of the owner, never depend on one project's files or stack, and never list which projects use or need something. Use generic examples (`my-app`, "a project that deploys from `main`").
- A task that only fits one project belongs in that project's repository, not in `prompts/` here. If such a task comes up, say so and propose where it goes.
- Before proposing a commit, check the diff for names of the owner's other repositories and remove them.

## Overrides of shared rules
None.
