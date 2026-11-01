[Docs index](../en/README.md)

# Public release checklist

<!--
Template from claude-shared-rules. Copy to docs/working/PUBLIC_RELEASE.md, link it from both
docs indexes, and delete items that cannot apply. The procedure behind each item:
~/repos/claude-shared-rules/docs/en/PUBLIC_RELEASE.md. Record each result with its date;
mark an item deferred (with a reason) or not applicable instead of deleting it once work starts.
Delete this comment.
-->

The repository is private. Making it public is the owner's decision and action. Every item below covers all refs that will be visible on GitHub, not only the current tree.

## 1. Scope
- [ ] `git ls-remote origin` listed; the owner decided which branches and tags are published. Unpublished refs deleted on GitHub.
- [ ] `refs/pull/*` reviewed: their commits are covered by the scan below.
- [ ] Local branches to publish are pushed.

## 2. History
- [ ] Secret scan over all history: tool, version, command, date, result.
- [ ] Every finding reviewed and resolved.
- [ ] Commit identities: only the owner's account with its `noreply` address.
- [ ] No AI co-author lines.
- [ ] No `.env*`, local settings, build output, or logs ever committed.
- [ ] No local absolute paths, personal email addresses, or other personal data.

## 3. Content
- [ ] Identifiers (account and resource IDs, hostnames): each one kept, moved, or removed by owner decision.
- [ ] Third-party material and licenses checked.
- [ ] Internal notes (`CLAUDE.md`, `prompts/`, logs): owner decided whether they stay public.
- [ ] GitHub-side data reviewed by the owner: pull requests, issues, workflow logs and artifacts, releases, wiki.

## 4. Presentation
- [ ] `LICENSE` chosen by the owner; no dependency conflicts.
- [ ] README status and quick start accurate (English and Japanese).
- [ ] `SECURITY.md`: added, or not needed with a reason.
- [ ] `CONTRIBUTING.md` and templates: added, or not wanted.

## 5. Final checks
- [ ] Tests, lint, and build pass on the commit to publish; CI green after the owner's push.
- [ ] Dependency audit clean for production dependencies.
- [ ] Secret scan repeated on the final commit.

## 6. Switch (owner)
- [ ] Visibility changed to public on: date.

## 7. GitHub settings right after (owner)
- [ ] Private vulnerability reporting.
- [ ] Secret scanning push protection.
- [ ] Dependabot alerts, or no dependencies.
- [ ] Ruleset on the default branch: no force push, no deletion, required checks if CI exists.
- [ ] Actions: disabled, or restricted actions, read-only `GITHUB_TOKEN`, approval for outside pull requests.
- [ ] Unused features (Wiki, Projects, Discussions, Issues) turned off.
- [ ] Setting names checked against GitHub Docs on: date.

## 8. Verification
- [ ] Signed-out browser shows only the intended refs and files.
- [ ] README quick start works from a clean directory without credentials.
- [ ] No secret scanning alerts.
- [ ] README status updated.
