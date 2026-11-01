# Task: prepare this repository for public release

Run this in a Claude Code session whose working directory is the target repository. Talk to the owner in Japanese. Follow every shared rule and the project's `CLAUDE.md`; this prompt adds the task, not new rules.

## Goal

The owner can decide to make the repository public with every item of `docs/working/PUBLIC_RELEASE.md` done, deferred with a reason, or marked not applicable. Making it public, and the GitHub settings after it, are the owner's steps; this task describes them and does not perform them.

## Constraints

- The first response is investigation and a proposal only: no file change, no tool install, no commit.
- Do not push, rewrite history, change GitHub settings, or create or edit anything on GitHub (issues, pull requests, releases, comments). Describe the exact owner step instead.
- Installing a scanner or any other tool needs the owner's approval; state name, version, source, and license when asking. It is never a project dependency.
- No paid service. Every GitHub feature proposed must be free for this repository.
- A real secret is reported at once and treated as compromised. Rotating it is the owner's call. Rewriting history needs the owner's explicit instruction.

## Read first

`CLAUDE.md`, `.gitignore`, the docs indexes, CI workflows, deployment docs if any, and `~/repos/claude-shared-rules/docs/en/PUBLIC_RELEASE.md`, which holds the procedure and commands for every step below.

## Steps

1. **Checklist.** If `docs/working/PUBLIC_RELEASE.md` does not exist, propose creating it from `~/repos/claude-shared-rules/templates/PUBLIC_RELEASE.md`, with the items that cannot apply removed and the reason stated.
2. **Scope.** Run `git ls-remote origin`. List every branch, tag, and `refs/pull/*` ref, and whether local branches are ahead of or behind their remote. Ask the owner which branches and tags are published.
3. **History.** Run the secret scan (after approval if the tool must be installed) and the manual checks, over all refs to be published. Report the tool, version, command, and result, and review every finding.
4. **Content.** Inventory identifiers, third-party material, and internal notes in the tree and the history. For each, recommend keep, edit, or remove with the reason. List the GitHub-side data the owner must review on GitHub; you cannot see it without the owner's tools.
5. **Presentation.** Check `LICENSE` against the dependencies' licenses, and the README status and quick start. Draft `SECURITY.md` or `CONTRIBUTING.md` only if the owner wants them.
6. **Final checks.** Run the project's tests, lint, build, and dependency audit on the commit to publish.
7. **Owner steps.** Write the switch and the GitHub settings for this repository as numbered owner steps, with setting names checked against current GitHub Docs and the date checked. Say which settings apply here (for example "no workflows: disable Actions").
8. **Record and propose commits.** Update the checklist with each result and date. Report in Japanese: what is clean, what the owner must decide (`要確認`), and the owner steps. Propose commits per `git.md`. Suggested subject: `docs: add public release checklist`.

## Acceptance

- The scan covers every ref to be published; tool, command, and result are recorded; every finding is resolved.
- Every identifier and internal note has an owner decision.
- Every checklist item is done, deferred with a reason, or not applicable.
- The owner has the exact steps for the switch and the settings right after it.
