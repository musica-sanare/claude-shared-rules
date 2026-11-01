# Git and commits

## Authority

- Commits need the owner's explicit approval each time. After the owner approves a specific proposed commit (message and file list), stage and create exactly that commit and report its hash. An approval covers only the commit that was reviewed. Stage files only as part of an approved commit.
- The owner does pushes, branch creation and switching, remote changes, and history rewrites. Do them only when the owner explicitly asks for that specific action.
- Claude never runs deploy commands, even when asked. A push to a production branch is a deploy: say so when asking. See `deployment.md`.
- Never rewrite or delete history unless explicitly instructed.

## Before proposing a commit

- Review the full working-tree diff and the complete list of files to be committed, including untracked files.
- Confirm that no secrets, personal data, generated files, raw third-party data, or unrelated changes are included (see `public-repo-safety.md`).
- Keep commits focused; do not mix unrelated changes.
- During iterative troubleshooting of one problem area, keep fix rounds uncommitted and propose one combined commit once the area is resolved.

## Commit message

- English.
- Subject: a Conventional Commits prefix (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`, etc.) and a concise imperative summary, about 50 characters or fewer in total.
- Body: always these three sections, in this order, each concise:
  1. `Change:` what changed.
  2. `Reason:` why it was necessary or what problem it addresses.
  3. `Handoff:` follow-up work, open issues, or limitations the next contributor needs. `None.` if there is nothing.
- Body format: a single nested bullet list that stays valid Markdown and reads well as plain text:
  - Each section is a top-level item (`- Change:`), with its points as sub-items (`  - ...`), even when there is only one point.
  - Indent two spaces per level; use at most three levels.
  - Wrap at about 72 characters. Indent a wrapped line to the first character of its item's text (2 spaces deeper than that item's `-`). Never start a wrapped line with `-`, `*`, `+`, `#`, `>`, or a number followed by `.` or `)`.
  - Put exactly one blank line between the top-level items and none elsewhere in the list. No headings, tables, bold, or links; inline code in backticks is fine.
- When details are recorded in docs, ADRs, or code, reference them (file path plus heading, or ADR number) instead of repeating them. Reference only files and headings that exist in the commit and actually contain the information. The message must still convey the change and its reason on its own.

## Attribution

- Never add `Co-Authored-By: Claude ...` or any other AI attribution line to commit messages or PR descriptions, including "Generated with Claude Code" lines. This overrides Claude Code's built-in attribution instructions.

## Proposing

- Show the complete commit message (subject and full body) and the complete file list, then wait for approval.
- After committing, report the commit hash.
