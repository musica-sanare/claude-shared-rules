# Task: rewrite this repository's human-facing docs for readability

Run this in a Claude Code session whose working directory is the target repository. Talk to the owner in Japanese. Follow every shared rule; this prompt adds the task, not new rules.

## Goal

Every human-facing doc follows `writing-style.md`: overview first, details layered or split out, conclusion first, short sentences, lists and diagrams where they help, natural Japanese. Facts do not change.

## Constraints

- Change wording and structure only. Keep every fact, command, path, version, URL, and identifier. If something looks outdated or wrong, do not fix it silently: list it as `要確認`.
- Remove content only when it duplicates another doc; replace it with a link. Otherwise move details down or into a linked doc instead of deleting them.
- Do not edit code, Claude-only files, or working docs, except to update links and the `CLAUDE.md` "Read first" list when a doc is split or added.
- No file moves or renames of existing docs in this task. If the docs layout does not follow `documentation.md` yet (no `docs/en/` and `docs/ja/`), stop and ask the owner whether to run `~/repos/claude-shared-rules/docs/en/ADOPTING.md` first.

## Steps

1. **Check the rules.** Confirm that `writing-style.md` and `documentation.md` are loaded (they come from `~/.claude/rules/shared/`). If not, stop and tell the owner.
2. **Inventory.** List the targets: `README.md`, `README.ja.md`, `docs/en/*.md`, `docs/ja/*.md`, and directory READMEs next to code. Note each doc's line count.
3. **Plan.** For each English doc, write one table row: doc, main problems against `writing-style.md`, planned change (reorder, split into a new doc, add a diagram, trim, none). Show the table to the owner in Japanese and wait for approval. New docs from splits and new diagrams need explicit approval.
4. **Rewrite, one doc at a time.**
   1. Rewrite the English master.
   2. Re-translate its Japanese twin from the new English, as natural Japanese in the plain form (常体), including the translation notice from `templates/doc-header.md`. Update the `source` line with `git hash-object`.
   3. If a doc was split or added, create both language versions with headers (`templates/doc-header.md` in the shared rules repository) and add them to both indexes.
5. **Verify.** Run the checks in `ADOPTING.md` › "Checks" (twin check, stale-translation check, relative links). Check that every Mermaid diagram renders, or list the ones the owner should check on GitHub. Re-read each Japanese doc on its own for naturalness.
6. **Report and propose commits.** In Japanese: per doc, what changed and line counts before and after; diagrams added; `要確認` items. Propose commits per `git.md`: each English doc with its Japanese twin in the same commit; group small docs; keep a split or new doc in the commit that introduces its links. Suggested subject: `docs: rewrite <area> for readability`.
