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
- If a secret is found already committed, tell the owner immediately and treat it as compromised; rotating it is the owner's call. Do not rewrite history without explicit instruction.
