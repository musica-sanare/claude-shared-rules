# Task: remove an extra doc translation

Run this in a Claude Code session whose working directory is the target repository. Talk to the owner in Japanese. Follow every shared rule and the project's `CLAUDE.md`; this prompt adds the task, not new rules.

The owner names the translation to remove when starting the task (for example Spanish, `es`). Below, `<lang>` means that code. Known targets: `audio-spectrum-app` and `lyrics-video-app` (Spanish).

## Goal

Human-facing docs exist in English (master) and Japanese only, as `documentation.md` requires. Every trace of the `<lang>` doc translation is gone, links still work, and nothing else changes.

## Scope

- Remove: `docs/<lang>/`, `README.<lang>.md`, the `<lang>` entry in every language switcher (for example `| Español`), links to `<lang>` docs from indexes and other docs, and `CLAUDE.md` text that describes or requires the `<lang>` doc translation.
- Keep: the product's `<lang>` UI and content (for example `src/**/i18n/<lang>.json`, locale lists, `Español` as a UI language name). Keep working docs in `docs/working/` as they are; they record history.
- Keep scripts, tests, and CI unless they exist only to check `<lang>` doc twins. Remove or adjust those, and say so in the plan.

## Steps

1. **Inventory.** List the files to delete and every file that references them: `git grep -n -e 'docs/<lang>' -e 'README.<lang>' -e '<language name in that language>'`, then sort each hit into "remove", "edit", or "keep (product UI or working doc)". Show the list to the owner and wait for approval.
2. **Delete** the `<lang>` docs with `git rm`.
3. **Edit references.** Remove the `<lang>` switcher entries and links in English docs and in Japanese twins. Update `CLAUDE.md` so its documentation section matches the shared rule (or drop the section if nothing project-specific remains).
4. **Refresh Japanese source lines.** Editing an English doc changes its blob hash, so update the `source` line of each Japanese twin with `git hash-object`.
5. **Verify.** Run the checks in `~/repos/claude-shared-rules/docs/en/ADOPTING.md` › "Checks" (twin check, stale-translation check, relative links). Confirm `git grep` finds no remaining `<lang>` doc references outside the "keep" list. Run the project's tests if any were touched.
6. **Report and propose one commit.** In Japanese: files deleted, files edited, items kept and why, check results. Propose one commit per `git.md`. Suggested subject: `docs: drop <lang> doc translation`.
