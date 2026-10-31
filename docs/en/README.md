English | [日本語](../ja/README.md) · [Repository README](../../README.md)

# claude-shared-rules documentation

How to install the shared Claude Code rules, adopt them in a project, and override them.

## Guides

| Document | Description |
|---|---|
| [Setup](SETUP.md) | Install on this or a new machine, verify, update, uninstall, and known limitations. |
| [Adopting the shared rules](ADOPTING.md) | Checklist for bringing a new or existing project under the shared rules. |
| [Overrides and opt-outs](OVERRIDES.md) | How a project adds to, replaces, or opts out of a shared rule. |

## Source files (English only)

| Location | Description |
|---|---|
| [`rules/`](../../rules/) | The rule files Claude loads in every project. Only rule files live here. |
| [`templates/`](../../templates/) | Files a project copies when adopting the rules: `CLAUDE.md` skeleton, docs index templates, doc header snippets. |
| [`optional/`](../../optional/) | Opt-in rules that load only when a user links them, such as Kansai-dialect conversation. |
| [`prompts/`](../../prompts/) | Task prompts a Claude Code session in a project follows, such as rewriting its docs for readability. |

## Working docs (English only)

None yet. Working docs go in `docs/working/`.
