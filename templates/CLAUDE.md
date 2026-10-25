# Project instructions for Claude Code

<!--
Template from claude-shared-rules. The shared rules (language, Git, documentation,
public-repository safety, GitHub workflow, overrides) load from ~/.claude/rules/shared/.
Do not copy them here. Keep only rules specific to this project, then delete this comment.
-->

## Product
<!-- One short paragraph: what this project is and who it is for. -->

## Read first
Before changing code or docs, read:
- `docs/en/README.md` (docs index)
- `docs/en/SPEC.md`
- `docs/en/ARCHITECTURE.md`
- `docs/working/DECISIONS.md`

If any path does not exist, report it rather than silently inventing its contents.

## Project principles
<!-- Non-negotiable product rules specific to this project. Product UI localization belongs here. -->

## Engineering
<!-- Stack, package manager, commands for lint/type-check/test/build, and project conventions. -->

## Workflow
<!-- How work is planned and reported in this project (phases, prompts, acceptance criteria). -->

## Overrides of shared rules
None.

<!--
Format for each entry (relaxing or replacing a shared rule):
- `documentation.md` › "Every stable doc starts with a language switcher": not applied to
  `docs/en/API_REFERENCE.md`, which is generated. Reason: the generator overwrites the file.
To opt out of a whole shared rule file, use claudeMdExcludes in .claude/settings.json instead.
-->
