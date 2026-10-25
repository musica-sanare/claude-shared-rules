English | [日本語](../ja/ADOPTING.md) · [Docs index](README.md)

# Adopting the shared rules

A checklist for bringing a project under the shared rules. A later Claude Code session can follow it step by step. Discuss each step with the owner in Japanese and get approval for each commit.

## Before you start

- [ ] The shared rules are active on this machine and appear in `/context` ([Setup](SETUP.md)).
- [ ] The working tree is clean, or the owner has said how to handle existing changes.
- [ ] Read the project's current `CLAUDE.md` (if any) and list every Markdown file in the repository.

## New project

- [ ] Copy [`templates/CLAUDE.md`](../../templates/CLAUDE.md) to the project root and fill in only project-specific rules.
- [ ] Create `docs/en/README.md` and `docs/ja/README.md` from [`templates/docs-index.en.md`](../../templates/docs-index.en.md) and [`templates/docs-index.ja.md`](../../templates/docs-index.ja.md).
- [ ] Write a thin `README.md` and `README.ja.md` (see step 8 below).
- [ ] Add a `.gitignore` that excludes `.env` files and other local secrets.
- [ ] Run the [checks](#checks).

## Existing project

### 1. Classify every Markdown file

Make a table with one row per file: current path, class, new path. Classes ([`rules/documentation.md`](../../rules/documentation.md)):

| Class | New location | Translated |
|---|---|---|
| Claude-only (`CLAUDE.md`, `.claude/**`, `prompts/**`, `.ai-eval/**`) | unchanged | no |
| Working doc (ADR log, plans, acceptance logs, research and handoff notes) | `docs/working/` | no |
| Stable doc (spec, architecture, design, data model, algorithms, guides) | `docs/en/` | yes, into `docs/ja/` |
| Directory README next to code | unchanged | no; linked from the indexes |

Also list data files read by code that live under `docs/`; they move out (for example to `data/`). Show the table to the owner and ask about unclear rows.

### 2. Move and rename (commit 1)

- [ ] Move each file with `git mv` to its new path, renaming it to `UPPER_SNAKE_CASE.md` if needed. On case-insensitive file systems (macOS default), rename in two steps: `git mv docs/spec.md docs/spec.tmp.md` then `git mv docs/spec.tmp.md docs/en/SPEC.md`.
- [ ] Make no content edits in this commit, so Git records clean renames.
- [ ] Propose the commit (for example `docs: move docs into en and working folders`).

### 3. Fix every reference

- [ ] Search for each old path and file name in docs, `CLAUDE.md` ("Read first" lists), code comments, CI config, scripts, and package metadata, and update them.
- [ ] In docs, turn bare paths in backticks that refer to other docs into relative Markdown links.

### 4. Add headers

- [ ] Add the language switcher and back-to-index link to every stable doc in `docs/en/` ([`templates/doc-header.md`](../../templates/doc-header.md)).

### 5. Write the indexes

- [ ] Write `docs/en/README.md` listing every doc (stable, working, directory READMEs) with a one-line description.
- [ ] Write `docs/ja/README.md` with the same entries; mark working docs and other English-only files "英語のみ".

### 6. Translate stable docs

- [ ] For each file in `docs/en/`, write `docs/ja/<same name>` with the header, the translation notice, and the `source` comment holding `git hash-object docs/en/<name>`.
- [ ] Translate the meaning, not word for word. Keep code, commands, paths, and identifiers unchanged.

### 7. Slim the project `CLAUDE.md`

- [ ] Remove sections now covered by the shared rules (language policy for conversation and repository text, Git and commit conventions, public-repository safety). Keep anything stricter or project-specific.
- [ ] Keep product UI localization rules (supported locales, translation files, locale handling) in the project; they are not shared.
- [ ] Add `## Overrides of shared rules` with an entry for each deliberate difference, or `None.` ([Overrides and opt-outs](OVERRIDES.md)).
- [ ] Update "Read first" to the new doc paths.
- [ ] If a project has no `CLAUDE.md`, create one from the template.

### 8. Thin READMEs

- [ ] Reduce `README.md` to a one-paragraph overview, status, a minimal quick start, and links to `README.ja.md` and `docs/en/README.md`. Move longer content into stable docs.
- [ ] Write `README.ja.md` as its translation, linking to `README.md` and `docs/ja/README.md`.

### 9. Opt-outs (only if needed)

- [ ] If a whole shared rule file does not fit the project, add a `claudeMdExcludes` entry ([Overrides and opt-outs](OVERRIDES.md#3-opting-out-of-a-whole-rule-file)) and confirm with `/context`.

### 10. Commit (commit 2, and 3 if useful)

- [ ] Steps 3 to 8 change English docs, so their Japanese twins go in the same commit. A reasonable split is: commit 2 for references, headers, indexes, translations, and READMEs; commit 3 for the `CLAUDE.md` changes.
- [ ] Commits made before adoption keep their messages; do not rewrite history to match the new conventions.

## Checks

Run these from the project root before proposing each commit.

- [ ] Every English doc has a Japanese twin and vice versa (no output means OK):

  ```bash
  diff <(ls docs/en) <(ls docs/ja)
  ```

- [ ] No Japanese translation is stale (no output means OK):

  ```bash
  for ja in docs/ja/*.md README.ja.md; do read -r src rec <<< "$(sed -n '1s/^<!-- source: \(.*\) blob \([0-9a-f]*\) -->$/\1 \2/p' "$ja")"; [ -n "$rec" ] && [ "$rec" = "$(git hash-object "$src")" ] || echo "stale or missing source line: $ja"; done
  ```

- [ ] Every relative link in Markdown resolves to an existing file. Check by hand or with a link checker; record the tool used.
- [ ] `/context` in a new session shows the shared rules and the project's `CLAUDE.md`.
- [ ] Nothing in the commit breaks [`rules/public-repo-safety.md`](../../rules/public-repo-safety.md).
