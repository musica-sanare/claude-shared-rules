English | [日本語](README.ja.md)

# claude-shared-rules

Claude Code rules shared by every project on the owner's machine: conversation and repository language, Git and commit conventions, a bilingual documentation layout, public-repository safety, and GitHub workflow. They are activated once through `~/.claude/rules/` and can be extended, overridden, or opted out of per project.

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
