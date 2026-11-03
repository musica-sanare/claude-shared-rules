# Decisions

Architecture decision records for this repository. Newest last. Each record states the context, the decision, and its consequences.

## ADR-001: Billing guard fails safe

- Date: 2026-11-03
- Status: Accepted

### Context

Unexpected charges are the owner's highest-risk concern ([`rules/paid-services.md`](../../rules/paid-services.md)). The first billing guard matched regular expressions against the whole command text. A review on 2026-11-03 found both kinds of error:

- False negatives: code that calls a paid API when run (`python3 app.py`, `python3 -c 'import anthropic'`), plain installs that pull in a paid SDK (`uv sync`), unlisted runners and CLIs (`uvx llm`, `stripe`), scheduling (`crontab`, `gh workflow run`), MCP servers that call paid APIs, commands typed into the Terminal panel, and browser pages for API keys and spending limits.
- False positives: text inside heredocs and quotes. In one project, a Python heredoc that only rewrote docs was blocked because the docs contained `brew install` and the English word "together", which is also a package name (Together AI).

### Decision

Defense in three layers, with failing safe preferred over convenience:

1. **Account settings** (owner): no payment method where none is needed, prepaid credits without auto-reload, hard spending limits, Claude extra usage turned off. This layer cannot be bypassed. See [Setup § Account settings](../en/SETUP.md#account-settings).
2. **Billing guard hook**: parses commands with the lexer shared with the deploy guard ([`hooks/lib/shell-lex.awk`](../../hooks/lib/shell-lex.awk)), so text for text-only commands does not match. Code given to an interpreter (inline, heredoc, script file, package script) is checked as code. It also:
   - scans manifests and lock files on plain installs;
   - flags code it cannot read (a missing script, code on standard input);
   - while credentials for a paid service are available (environment, shell profile, `.env`, cloud CLI logins), asks before any command that runs code;
   - asks before MCP servers that are not on an allowlist (the Claude apps' own servers plus `~/.claude/billing-guard-mcp-allowlist`) and before scheduled tasks;
   - applies Bash checks to commands typed into the Terminal panel;
   - denies API key, credit, spending-limit, and budget pages as well as billing pages.
3. **Rule**: Claude edits files with the Edit or Write tool, never adds credentials or scheduled jobs on its own, and does not start cloud sessions or routines where hooks do not run.

### Consequences

- More prompts, by design. The workaround for a false positive is the Edit or Write tool for file edits, or the owner running the command with `!`.
- Running tests or scripts in a project that keeps an API key in `.env` asks every time. Keeping keys out of projects Claude works on avoids this.
- The guard still cannot see Write and Edit tool calls, imports reached indirectly, browser clicks, or sessions where hooks do not run. The account settings and the rule cover those.
- The deploy guard now also checks commands typed into the Terminal panel. Its hook matcher in `~/.claude/settings.json` must include `mcp__.*__run_in_terminal` for this to take effect.
