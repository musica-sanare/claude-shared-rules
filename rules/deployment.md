# Deployment and remote resources

Production changes reach users only through the owner. Claude never deploys and never changes remote resources, even with approval; Claude prepares, the owner runs.

## Claude never runs

- Deploys, uploads of new versions, and promotions or rollbacks of versions.
- Commands that change remote resources: remote database migrations or writes, secret or variable changes, creating or deleting databases, buckets, queues, domains, routes, or access policies.
- Logins or logouts of cloud CLIs (`wrangler login`, `gcloud auth login`, and similar).
- Publishing packages or images to a registry (`npm publish`, `cargo publish`, `docker push`, and similar).

Commands this covers, also through `npx`, `pnpm exec`, `bunx`, and similar runners:

- Wrangler: `login`, `logout`, `deploy` and `publish` (except with `--dry-run`), `versions upload` and `versions deploy`, `rollback`, `secret`, `pages deploy`, any command with `--remote`, and resource writes (`d1`, `kv`, `r2`, `queues`, and others: `create`, `delete`, `put`, `execute`, `migrations apply`, ...) without `--local`.
- Other hosts and clouds: `vercel` (bare, `deploy`, `--prod`, `promote`, `rollback`, `env add`), `netlify deploy`, `firebase deploy`, `fly deploy`, `supabase db push`, `supabase functions deploy`, `supabase secrets set`, `gcloud ... deploy`, and the create, update, or delete commands of `aws`, `gcloud`, `az`, `doctl`, `kubectl`, and `helm`.
- Infrastructure as code: `terraform apply`, `terraform destroy`, `pulumi up`, `cdk deploy`, `sam deploy`, `serverless deploy`.
- Scripts that run any of these: `npm run`, `pnpm`, `yarn`, and `bun` scripts, Make targets, and shell scripts.

Allowed without asking: local and read-only commands such as `wrangler dev` (without `--remote`), `wrangler deploy --dry-run`, `wrangler types`, `--version`, and `--help`.

The deploy guard hook (`hooks/deploy-guard.sh`) denies these commands in every permission mode. It also denies package scripts, Make targets, and files whose names contain `deploy`, `publish`, `release`, or `rollback`. Never work around it: no rewriting, splitting, or obfuscating a command so it no longer matches. A guard that misses a command does not make the command allowed.

This applies in every permission mode and even when the owner approves the change. Prepare the exact commands, the expected output, and the checks afterwards, then ask the owner to run them in their own terminal or with a `!` command. Read-only commands against remote resources (listing, status, dry runs) still need the owner's confirmation if they need a login.

## How projects deploy

- Deploy only through the hosting provider's Git integration (for example Cloudflare Pages or Workers Builds). A production deploy is the owner's push to the production branch.
- In each project's `CLAUDE.md` and deployment doc, state which branch push deploys to production. When asking the owner about a push to that branch, say that it deploys.
- A push to the production branch is the one deploy Claude may trigger, and only under `git.md`: the owner explicitly asks for that specific push after being told it deploys.
- Do not add deploy credentials to CI (GitHub Actions secrets or similar). Only the provider's Git integration holds deploy access.
- When a task needs something the Git integration cannot do (a remote migration, first-time setup), write it as an owner step: log in, run, verify, log out. Do not leave a cloud CLI logged in on the machine.
- For a new project, prefer a host that has Git integration and a free plan that stops at its limits instead of billing ([paid-services.md](paid-services.md)).
- A project that still deploys from a local CLI keeps working as documented until it is migrated. Do not migrate it without the owner's decision.
