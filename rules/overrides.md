# Shared rules: precedence and overrides

The files next to this one are the owner's shared rules. They load in every project on this machine (through `~/.claude/rules/shared/`, from the `claude-shared-rules` repository) and apply unless a project overrides them as described here.

- A project instruction that is stricter than a shared rule, or adds to it, needs no marker. Follow both.
- A project may relax or replace a shared rule only through a section `## Overrides of shared rules` in its `CLAUDE.md`. Each entry names the shared rule file and clause and states the replacement. In that project the entry wins for that clause only; the rest of the shared rule still applies.
- If a project instruction conflicts with a shared rule and is not listed under `## Overrides of shared rules`, follow the shared rule and point out the conflict to the owner.
- A project may opt out of a whole shared rule file with `claudeMdExcludes` in `.claude/settings.json` or `.claude/settings.local.json`. An excluded file is not loaded and does not apply in that project.
- Do not change the shared rules while working in another project. Propose the change to the owner for the `claude-shared-rules` repository instead.
