English | [日本語](../ja/README.md) · [Repository README](../../README.md)

# claude-shared-rules documentation

How to install the shared Claude Code rules, adopt them in a project, and override them.

## Guides

| Document | Description |
|---|---|
| [Setup](SETUP.md) | Install on this or a new machine, verify, update, uninstall, and known limitations. |
| [Adopting the shared rules](ADOPTING.md) | Checklist for bringing a new or existing project under the shared rules. |
| [Overrides and opt-outs](OVERRIDES.md) | How a project adds to, replaces, or opts out of a shared rule. |
| [Making a repository public](PUBLIC_RELEASE.md) | Checks before, the visibility switch, and the GitHub settings right after. |

## Source files (English only)

| Location | Description |
|---|---|
| [`rules/`](../../rules/) | The rule files Claude loads in every project. Only rule files live here. |
| [`templates/`](../../templates/) | Files a project copies when adopting the rules: `CLAUDE.md` skeleton, docs index templates, doc header snippets, public release checklist. |
| [`hooks/`](../../hooks/) | Hook scripts that enforce rules, registered in `~/.claude/settings.json`. See [Billing guard](SETUP.md#billing-guard) and [Deploy guard](SETUP.md#deploy-guard). |
| [`optional/`](../../optional/) | Opt-in rules that load only when a user links them, such as Kansai-dialect conversation. |
| [`prompts/`](../../prompts/) | Task prompts a Claude Code session in a project follows, such as rewriting its docs for readability. |

## Working docs (English only)

| Document | Description |
|---|---|
| [Public release checklist](../working/PUBLIC_RELEASE.md) | Status of this repository's own public release. |
| [Decisions](../working/DECISIONS.md) | Architecture decision records, such as why the billing guard fails safe. |
