# Paid services and billing risk

Unexpected charges are the owner's highest-risk concern. Claude never moves toward a paid or usage-billed service on its own judgment.

## Scope

- Paid service: anything that can charge the owner money, now or later. This includes:
  - LLM and AI APIs (Claude API / Anthropic SDK, OpenAI, Gemini, and similar);
  - cloud resources (compute, storage, databases, functions, egress);
  - SaaS plans, paid third-party APIs, paid tiers or add-ons of otherwise free services;
  - free tiers or trials that switch to billing when a limit is exceeded or the trial ends, or that require a payment method on file.
- Hard-capped free tier: a free tier that only throttles or stops when the limit is reached and can never bill. This is lower risk but still needs the owner's confirmation.

## Rules

- Never propose, recommend, or start implementing a paid service or a hard-capped free tier on Claude's own initiative. Prefer approaches with no added cost: local processing, existing free tooling, or doing the work inside the Claude Code session itself.
- Use such a service only after the owner names that specific service in chat and confirms it. Approval for one service does not extend to another service, a higher tier, or a different project.
- Before asking for confirmation, state:
  - the service and plan;
  - whether exceeding the free limit bills or only stops (say so if unknown; treat unknown as billing);
  - the expected cost or usage, and how to cap it (spending limits, budgets, alerts).
- If a task cannot be done without such a service, say so, explain why, and stop. Until the owner confirms, do not prepare for it: no SDK or client installs, no API calls, no `.env.example` key slots, no infrastructure or config.
- When a project already uses a paid service, do not expand its use (new endpoints, more calls, larger models, higher tiers, new regions) without the owner's confirmation.
- Never change a plan, tier, or billing setting of any service, by any means (dashboard, browser tool, CLI, API, MCP tool): no upgrades, downgrades, trials, add-ons, payment details, billing accounts, quota or spending-limit increases. Do not open billing, plan, payment, API key, credit, or spending-limit pages either. The owner does all of these, even when a task seems to require it; say what is needed and stop.
- The owner's account settings are the last line of defense: no payment method where none is needed, prepaid credits without auto-reload, hard spending limits, and Claude extra usage turned off (`docs/en/SETUP.md` § Account settings). Claude never changes them. If one seems missing, tell the owner.
- Never put a paid service's API key or other credentials in the environment, a shell profile, or a `.env` file, and never log a cloud CLI in. While such credentials are available, the billing guard asks before any code runs.
- Do not create anything that runs later or repeatedly and can call a paid service (cron or launchd jobs, CI workflows, scheduled tasks, cloud routines, `/loop` jobs) unless the owner asks for that specific job. Hooks do not run in cloud sessions, routines, or Cowork, so only this rule covers them; do not start those unless the owner asks.
- Use an MCP server without asking only if the billing guard allows it: the Claude apps' own servers, or one the owner added to `~/.claude/billing-guard-mcp-allowlist`. Never edit that file; the owner decides what to trust.
- Write and edit files with the Edit or Write tool, not with shell heredocs or scripts. The billing guard checks code passed to an interpreter as code, so a script that only rewrites text can still be stopped.
- Credentials Claude can use must not be able to change billing. When asking the owner for a token, key, service account, or login, name the minimum permissions the task needs and say explicitly that billing, plan, payment, and account-admin permissions must be left out. If a credential Claude is given has, or may have, such permissions, tell the owner before using it. Never create or widen a credential yourself.
- The billing guard hook (`hooks/billing-guard.sh`) may ask the owner about a command or block a tool call. Never work around it: no rewriting, splitting, or obfuscating a command so it no longer matches, and no moving it into a file or another tool to hide it. The only acceptable change after a block is the one its message names (the Edit or Write tool for a file edit); otherwise tell the owner.
- When reviewing or reading code that would call a paid service in loops, retries, CI, or scheduled jobs, point out the billing risk to the owner.
