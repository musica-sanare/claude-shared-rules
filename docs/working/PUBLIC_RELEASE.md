[Docs index](../en/README.md)

# Public release checklist

The owner made the repository public on 2026-11-01. This checklist records how it was prepared. Every item below covers all refs that will be visible on GitHub, not only the current tree. Procedure: [Making a repository public](../en/PUBLIC_RELEASE.md).

## 1. Scope
- [x] `git ls-remote origin` listed on 2026-11-01: `main`, `dev`, `refs/pull/1/head`; no tags. The owner decided on 2026-11-01 that `main` and `dev` are both published.
- [x] `refs/pull/1/head` (`049d314`) is an ancestor of `origin/main` and covered by the scan.
- [x] Local `dev` is pushed. On 2026-11-01 the owner merged `dev` into `main` (`432d858`) and pushed both; `main`, `dev`, and `HEAD` on GitHub point to `432d858`.

## 2. History
- [x] Secret scan on 2026-11-01: gitleaks 8.30.1, `gitleaks git --redact -v .`, 15 commits, no leaks found. Repeat with `--log-opts="--all"` on the final commit (section 5).
- [x] No findings to resolve.
- [x] Commit identities: all `musica-sanare` with the GitHub `noreply` address; the merge of pull request 1 is committed by GitHub.
- [x] No AI co-author lines.
- [x] Files ever committed equal the current tracked files; no `.env*`, local settings, build output, or logs.
- [x] No local absolute paths (`/Users/`, `/home/`) and no email address other than the `noreply` one.

## 3. Content
- [x] Identifiers: none (no cloud accounts, resources, or hostnames).
- [x] Third-party material: none; all text is original. The docs cite Claude Code and GitHub documentation by link only.
- [x] Internal notes: the repository is rules, docs, and prompts by design; they stay public.
- [x] Names of the owner's other repositories: two prompts named them. The owner decided on 2026-11-01 that the history may keep them, because those repositories will be published later. The current tree no longer names them: the list of targets was dropped from `prompts/remove-doc-translation.md`, and the prompt specific to one project was removed (owner decision, 2026-11-01). `CLAUDE.md` now forbids such names.
- [x] GitHub-side data reviewed by the owner on 2026-11-01: pull request 1 has no description or comments. No workflows, releases, or wiki exist.

## 4. Presentation
- [x] `LICENSE`: MIT, `Copyright (c) 2026 musica-sanare`. No dependencies.
- [x] README status: replaced "initial version; not yet activated" with the text the owner chose on 2026-11-01 (English and Japanese).
- [x] `SECURITY.md`: not needed. The repository has no service or package; the hooks run only on the owner's machine. Private vulnerability reporting is still enabled (section 7).
- [x] `CONTRIBUTING.md` and templates: not added. The owner decided on 2026-11-01 not to accept outside contributions in general.

## 5. Final checks
- [x] `hooks/tests/run.sh` passes on the commit to publish: 762 checks, 0 failed at `432d858` (2026-11-01).
- [x] Dependency audit: not applicable, no dependencies.
- [x] Secret scan repeated on the final commit: `gitleaks git --log-opts="--all" --redact .` at `432d858`, gitleaks 8.30.1, no leaks found (2026-11-01). Identities unchanged: only the `noreply` address.

## 6. Switch (owner)
- [x] Visibility changed to public on 2026-11-01.

## 7. GitHub settings right after (owner)
- [x] Private vulnerability reporting enabled.
- [x] Secret scanning push protection enabled.
- [x] Dependabot alerts: not applicable, no dependencies.
- [x] Ruleset on `main`: no force push, no deletion. No required checks (no CI) and no required pull request: the owner chooses a pull request or a direct merge and push case by case (2026-11-01).
- [x] Actions: disabled (no workflows).
- [x] Unused features turned off: Wiki, Projects, Discussions, Issues (no outside contributions). Pull requests cannot be turned off; close outside ones.
- [x] Setting names matched the GitHub UI when the owner applied them on 2026-11-01.

## 8. Verification
- [x] Signed-out browser shows only `main`, `dev`, and the intended files (owner, 2026-11-01).
- [x] README quick start (`git clone https://github.com/musica-sanare/claude-shared-rules.git`) works without credentials: anonymous HTTPS clone succeeded at `432d858` (2026-11-01).
- [x] No secret scanning alerts (owner, 2026-11-01).
- [x] README status still accurate after the switch.
