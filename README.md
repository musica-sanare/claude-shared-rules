English | [日本語](README.ja.md)

# claude-shared-rules

Claude Code rules shared by every project on the owner's machine. They cover conversation and repository language, Git and commits, bilingual docs and their writing style, public-repository safety, GitHub workflow, and approval before any paid service. Activate them once through `~/.claude/rules/`; each project can then add to, override, or opt out of them.

**Status:** initial version; not yet activated.

## Quick start

```bash
git clone https://github.com/musica-sanare/claude-shared-rules.git ~/repos/claude-shared-rules
mkdir -p ~/.claude/rules
ln -s ~/repos/claude-shared-rules/rules ~/.claude/rules/shared
```

Then start a new Claude Code session and check `/context`. Details: [Setup](docs/en/SETUP.md).

## Documentation

- [Documentation index](docs/en/README.md)
- [Setup](docs/en/SETUP.md) · [Adopting the shared rules](docs/en/ADOPTING.md) · [Overrides and opt-outs](docs/en/OVERRIDES.md)

## License

[MIT](LICENSE)
