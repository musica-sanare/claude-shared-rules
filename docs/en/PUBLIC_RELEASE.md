English | [日本語](../ja/PUBLIC_RELEASE.md) · [Docs index](README.md)

# Making a repository public

The common procedure for changing a private GitHub repository to public: what to check before, how to switch, and which GitHub settings to apply right after. It is for the owner and for a Claude Code session preparing a project. Copy the [checklist template](../../templates/PUBLIC_RELEASE.md) into the project and start a session with the [preparation prompt](../../prompts/prepare-public-release.md).

> [!WARNING]
> Making a repository public publishes its whole history, not only the current files. A secret that was committed and later deleted is still readable. Every check below covers all branches, tags, and pull request refs that will be visible.

## Who does what

- Claude investigates, runs local checks, drafts files, and records results in the project's checklist.
- The owner makes every decision marked below, pushes, changes GitHub settings, and switches the visibility. Claude describes these steps; it does not perform them (`github-workflow.md`, `git.md`).
- Publishing a repository is not a deploy. If pushing to a branch deploys the project, say so whenever a push is involved (`deployment.md`).

## Overview of the steps

1. [Before: decide the scope](#1-decide-what-will-be-public)
2. [Before: scan the history](#2-scan-the-history)
3. [Before: review content and GitHub-side data](#3-review-content)
4. [Before: prepare the presentation](#4-prepare-the-presentation)
5. [Before: final checks](#5-final-checks)
6. [Switch the visibility](#6-switch-the-visibility) (owner)
7. [After: apply GitHub settings](#7-apply-github-settings-right-after) (owner)
8. [After: verify and record](#8-verify-and-record)

## 1. Decide what will be public

List every ref on GitHub, not only local branches:

```bash
git ls-remote origin
```

- Branches and tags: the owner decides which are published. Delete the rest on GitHub before switching.
- `refs/pull/<n>/head`: every pull request keeps its head commits on GitHub, even after the branch is deleted or force-pushed. These commits become public too, and only GitHub Support can remove them.
- Make sure the local branches you want published are pushed, so the scan below covers the same commits.

## 2. Scan the history

Run a secret scanner over all history. `gitleaks` is the default (install with Homebrew after the owner's approval; it is not a project dependency):

```bash
gitleaks git --log-opts="--all" --redact .
```

Then check by hand what a scanner does not catch:

| Check | Command |
|---|---|
| Commit identities (author and committer) | `git log --all --format='%an <%ae> / %cn <%ce>' \| sort -u` |
| AI co-author lines | `git log --all --format=%B \| grep -i co-authored-by` |
| Every file ever committed | `git log --all --name-only --format= \| sort -u` |
| Local absolute paths | `git log --all -p \| grep -nE '/Users/\|/home/'` |
| Email addresses | `git log --all -p \| grep -noE '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[a-z]{2,}' \| sort -u` |

Expected results:

- Every identity is the owner's GitHub account with its `noreply` address.
- No `.env*` (except `.env.example`), `.dev.vars*`, build output, logs, or local settings files were ever committed.
- No local paths, personal email addresses, or other personal data.

If a real secret turns up, treat it as compromised: the owner revokes or rotates it first. Rewriting history needs the owner's explicit instruction, and it does not reach existing clones, forks, or `refs/pull/*`.

## 3. Review content

Go through the current tree and the history for material that is not secret but may not belong in public. The owner decides keep, edit, or remove for each item. Removing a file now does not remove it from history.

- Identifiers: cloud account IDs, resource IDs, internal hostnames, subdomains. Keep them only if they are not secrets and the build needs them.
- Third-party material: copied text, images, fonts, icons, data with license limits, AI model terms.
- Internal notes: `CLAUDE.md`, `prompts/`, verification logs, incident records, handoff notes. They often describe plans and open security items.
- GitHub-side data, which is not in Git but becomes public with the repository: pull request and issue text and comments, workflow run logs and artifacts, releases and their assets, the wiki. Check them on GitHub; delete or edit what should not be seen.

## 4. Prepare the presentation

- `LICENSE` chosen by the owner, and checked against the dependencies' licenses.
- `README.md` (and `README.ja.md`) with an accurate status and a quick start that works without access to private resources.
- `SECURITY.md` that points to private vulnerability reporting, if the project has code someone could find a vulnerability in.
- `CONTRIBUTING.md` and issue or pull request templates only if the owner wants outside contributions.
- Repository description and topics on GitHub (owner).

## 5. Final checks

- The project's tests, lint, and build pass on the commit to publish, and CI is green after the owner's push.
- The dependency audit (for example `npm audit --omit=dev`) reports no unresolved production vulnerabilities.
- Run the secret scan of [step 2](#2-scan-the-history) again on the final commit.
- Every item in the project's checklist is done, deferred with a reason, or marked not applicable.

## 6. Switch the visibility

The owner does this: **Settings → General → Danger Zone → Change repository visibility → Make public**.

## 7. Apply GitHub settings right after

Several protections are free on GitHub Free only for public repositories, so apply them right after the switch. Setting names change over time; check them against the current GitHub Docs and record the date checked.

1. **Settings → Advanced Security**: enable private vulnerability reporting, and push protection for secret scanning. Secret scanning itself runs automatically on public repositories. Enable Dependabot alerts if the project has dependencies.
2. **Settings → Rules → Rulesets**: a ruleset for the default branch that blocks force pushes and deletion. Add required status checks when the project has CI. Leave the bypass list empty unless the owner needs it. A ruleset does not stop a host's Git integration from deploying a push.
3. **Settings → Actions → General**:
   - No workflows: disable Actions.
   - With workflows: allow only the actions the workflows use, keep the default `GITHUB_TOKEN` permission read-only, and require approval for workflow runs from outside contributors' pull requests.
4. **Settings → General → Features**: turn off Wiki, Projects, Discussions, and Issues unless the owner wants them.

## 8. Verify and record

- Open the repository in a signed-out browser window and check that only the intended branches and files appear.
- Run the README quick start from a clean directory; a `git clone` over HTTPS must work without credentials.
- Check **Security → Secret scanning** for alerts.
- Record what was applied, with the date, in the project's checklist, and update the README status.
