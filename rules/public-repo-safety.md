# Public-repository safety

- Treat every repository, including its full Git history, as public on GitHub, even while it is private.
- Never commit:
  - secrets, API keys, tokens, credentials, private keys, or `.env` files;
  - personal data (names, email addresses, phone numbers, postal addresses) beyond what the owner has approved;
  - local absolute paths that reveal a user name (write `~/...` instead);
  - logs or transcripts that may contain any of the above.
- When environment variables exist, provide `.env.example` with placeholders only.
- When in doubt, ask. If anything about to be committed might be sensitive (for example cloud account or resource IDs, internal hostnames, third-party data with license limits, AI review logs, screenshots), stop, list each item with the reason for doubt, and wait for the owner's decision. Never decide silently in favor of committing.
- Before a repository is made public, inspect its complete history and scan it with a secret scanner (for example `gitleaks`; check its current docs first). Report the tool, the command, and the result to the owner.
- Preparing a public release follows the `claude-shared-rules` repository's `docs/en/PUBLIC_RELEASE.md`, with a checklist in the project's `docs/working/PUBLIC_RELEASE.md`. The scan covers every ref on GitHub (`git ls-remote origin`), including `refs/pull/*`, which survive branch deletion and force pushes. Pull request and issue text, workflow logs, releases, and the wiki become public too; list them for the owner to review.
- The visibility switch and the GitHub settings applied right after it are owner steps. Describe them; never perform them.
- If a secret is found already committed, tell the owner immediately and treat it as compromised; rotating it is the owner's call. Do not rewrite history without explicit instruction.
