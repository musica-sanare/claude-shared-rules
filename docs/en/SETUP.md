English | [日本語](../ja/SETUP.md) · [Docs index](README.md)

# Setup

The shared rules are activated by a symlink from `~/.claude/rules/shared` to this repository's `rules/` directory. Claude Code loads every `.md` file under `~/.claude/rules/` (recursively, following symlinks) in every project, before the project's own instructions. User-scope rules need no approval dialog.

Behavior described here was checked against the official Claude Code docs ([Memory](https://code.claude.com/docs/en/memory), [Settings reference](https://code.claude.com/docs/en/settings-reference), [Permissions](https://code.claude.com/docs/en/permissions)) on 2026-10-25. Re-check them when something does not work as described.

## Prerequisites

- macOS or Linux with `git`.
- Claude Code CLI or the desktop app's Code tab. Version 2.1.281 or later is recommended (needed for `"attribution": false`; 2.1.239 or later is needed for `claudeMdExcludes` to match a symlinked rule by its link path).
- A GitHub account with access to this repository.

## Install

1. Clone the repository:

   ```bash
   git clone https://github.com/musica-sanare/claude-shared-rules.git ~/repos/claude-shared-rules
   ```

2. Check that nothing already exists at the link location. This should print `No such file or directory`:

   ```bash
   ls -la ~/.claude/rules/shared
   ```

3. Create the link:

   ```bash
   mkdir -p ~/.claude/rules
   ```

   ```bash
   ln -s ~/repos/claude-shared-rules/rules ~/.claude/rules/shared
   ```

Personal rules that are not shared can still go directly in `~/.claude/rules/` as separate files.

## Verify

1. Start a **new** Claude Code session in any project. Running sessions do not pick up new or changed instructions.
2. Run `/context` and check the list under **Memory files**. Every file in `rules/` must appear:
   `overrides.md`, `language.md`, `documentation.md`, `git.md`, `public-repo-safety.md`, `github-workflow.md`.
3. Optionally, ask Claude in Japanese or English which shared rule files it has loaded, and check that it answers in Japanese.

If the files are missing, check the link with `ls -la ~/.claude/rules/` and that its target exists.

## Recommended settings (optional enforcement)

Rules are guidance, not enforcement. To enforce the no-attribution rule and to be asked before every push, add these keys to `~/.claude/settings.json`. Merge them into the existing file; do not replace it.

```json
{
  "attribution": false,
  "permissions": {
    "ask": ["Bash(git push *)"]
  }
}
```

- `"attribution": false` hides the commit trailer and PR attribution that Claude Code adds by default. It needs Claude Code 2.1.281 or later; earlier versions reject the value and skip the whole settings file. For older versions use this instead:

  ```json
  { "attribution": { "commit": "", "pr": "", "sessionUrl": false } }
  ```

- `Bash(git push *)` as an `ask` rule makes Claude Code prompt before any command that starts with `git push`, even in auto mode. It does not match pushes written another way, such as `git -C . push`, so it is a safety net, not a guarantee.

## Update

```bash
git -C ~/repos/claude-shared-rules pull
```

New sessions use the updated rules. Restart running sessions to pick them up.

## Uninstall

Remove the link (no trailing slash, so only the link is removed, not the repository's files):

```bash
rm ~/.claude/rules/shared
```

Then remove the optional settings from `~/.claude/settings.json` if you added them. The clone in `~/repos/claude-shared-rules` can stay or be deleted separately.

## New machine

1. Install Git and Claude Code, and sign in to GitHub.
2. Follow [Install](#install).
3. Add the [recommended settings](#recommended-settings-optional-enforcement) if wanted.
4. Clone the project repositories and [verify](#verify) in one of them.

## Known limitations

- **Cloud sessions** (Claude Code on the web and other sessions that run on a remote machine) cannot see `~/.claude/` on this Mac, so the shared rules do not load there. Rules that must apply there have to be in the project's own `CLAUDE.md`.
- **Cowork sessions** skip a symlinked `~/.claude/rules/` directory or rule file that points outside the session's working directory, so the shared rules do not load there. Normal Claude Code sessions (CLI and the desktop Code tab) are unaffected.
- **Conflicts**: when a user rule and a project rule conflict, Claude Code itself does not make either win. The precedence in [Overrides and opt-outs](OVERRIDES.md) works only because the rules state it.
- **Windows** is not covered by these instructions.
