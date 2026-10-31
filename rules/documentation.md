# Documentation

Human-readable docs form a small site navigable by links, with an English master and a Japanese translation. How to write them: `writing-style.md`.

## Classes of Markdown

1. **Claude-only**: `CLAUDE.md`, `CLAUDE.local.md`, `.claude/**`, `prompts/**`, `.ai-eval/**`, and similar files written for Claude. English only, not translated, not part of the docs site.
2. **Working docs**: fluid documents mainly for development, such as the ADR log (`DECISIONS.md`), implementation and phase plans, acceptance logs, research notes, and handoff notes. Location: `docs/working/`. English only, not translated. Linked from both indexes; the Japanese index marks them "English only".
3. **Stable docs**: human-facing specification, architecture, design, data model, algorithms, and setup, development, deployment, and operations guides. English master in `docs/en/`, Japanese translation in `docs/ja/` with the same file name.

When a document's class is unclear, ask the owner.

## Source of truth and translation

- English is the source of truth. Read and design from the English version.
- Every file in `docs/en/` has a twin with the same name in `docs/ja/`, and `docs/ja/` contains nothing else.
- Any change to an English stable doc updates its Japanese twin in the same commit. If the translation cannot be done right away, tell the owner; never leave it silently stale.
- Each Japanese doc records the English content it was translated from as its first line, using the Git blob hash of the English file (`git hash-object <file>`, which works before committing):
  `<!-- source: docs/en/SPEC.md blob <hash> -->`
  Update the hash whenever the translation is brought up to date.
- Each Japanese doc carries a notice that it is a translation and that the English version prevails.

## Navigation

- Every stable doc starts with a language switcher (`English | 日本語`) and a link back to its index. Use the snippets in the `claude-shared-rules` repository's `templates/doc-header.md`.
- `docs/en/README.md` and `docs/ja/README.md` are indexes that list every doc (stable docs, working docs, and directory READMEs next to code) with a one-line description. Adding, renaming, or removing a doc updates both indexes.
- Root `README.md` is thin: a one-paragraph overview, status, a minimal quick start, and links into the docs. It links to `README.ja.md` and `docs/en/README.md`. `README.ja.md` is its thin Japanese twin and links to `README.md` and `docs/ja/README.md`. `README.ja.md` follows the same translation rules as `docs/ja/`.
- When a doc refers to another doc, use a relative Markdown link (`[Architecture](ARCHITECTURE.md)`), not a bare path in backticks. Links must work on GitHub.

## Files and locations

- Doc file names are `UPPER_SNAKE_CASE.md`; index files are `README.md`.
- Directory READMEs next to code (for example `bench/README.md`) may stay in place; link them from the indexes.
- Data files read by code (for example JSON fixtures) do not live in `docs/en/` or `docs/ja/`.
- When moving or renaming docs, use `git mv`, update every reference (other docs, `CLAUDE.md` "Read first" lists, code comments, CI, scripts), and keep moves in a commit separate from content edits.
