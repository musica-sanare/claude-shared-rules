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
- Never enter payment details, create billing accounts, raise quotas or spending limits, or upgrade plans. The owner does these.
- When reviewing or reading code that would call a paid service in loops, retries, CI, or scheduled jobs, point out the billing risk to the owner.
