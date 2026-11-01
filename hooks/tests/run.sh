#!/bin/bash
# Tests for hooks/deploy-guard.sh and hooks/billing-guard.sh.
# Feeds PreToolUse JSON to each hook under /bin/bash and checks the decision
# in every permission mode. Needs jq. Run: bash hooks/tests/run.sh

set -u
cd "$(dirname "$0")/.." || exit 1
hooks=$PWD
modes='default plan acceptEdits auto bypassPermissions dontAsk'
fail=0
count=0

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/app" "$fixture/site"
cat >"$fixture/app/package.json" <<'JSON'
{
  "scripts": {
    "dev": "wrangler dev",
    "build": "vite build",
    "check": "wrangler deploy --dry-run --outdir dist",
    "ship": "npm run build && wrangler deploy",
    "go": "npm run ship",
    "migrate": "wrangler d1 migrations apply DB --remote",
    "test": "vitest run",
    "pretest": "wrangler types",
    "wrangler": "echo shadowed"
  }
}
JSON
cat >"$fixture/site/package.json" <<'JSON'
{ "scripts": { "start": "vercel --prod" } }
JSON

decision() { # hook mode command [cwd]
  jq -nc --arg m "$2" --arg c "$3" --arg d "${4:-$fixture}" \
    '{tool_name:"Bash",permission_mode:$m,cwd:$d,tool_input:{command:$c}}' |
    /bin/bash "$hooks/$1" | jq -r '.hookSpecificOutput.permissionDecision // empty'
}

expect() { # hook expected command [cwd] -- expected is deny|ask|none|ask-or-deny
  local hook=$1 want=$2 cmd=$3 dir=${4:-$fixture} mode got ok
  for mode in $modes; do
    got=$(decision "$hook" "$mode" "$cmd" "$dir")
    [ -n "$got" ] || got=none
    ok=0
    case $want in
      ask-or-deny)
        case $mode in
          default | plan | acceptEdits) [ "$got" = ask ] && ok=1 ;;
          *) [ "$got" = deny ] && ok=1 ;;
        esac
        ;;
      *) [ "$got" = "$want" ] && ok=1 ;;
    esac
    count=$((count + 1))
    if [ $ok = 0 ]; then
      fail=$((fail + 1))
      printf 'FAIL %s [%s] want %s, got %s: %s\n' "$hook" "$mode" "$want" "$got" "$cmd"
    fi
  done
}

deny() { expect deploy-guard.sh deny "$@"; }
pass() { expect deploy-guard.sh none "$@"; }

# Cloudflare deploys and remote changes.
deny 'wrangler deploy'
deny 'npx wrangler deploy'
deny 'npx -y wrangler@4 deploy --env production'
deny 'wrangler --config wrangler.prod.toml deploy'
deny 'pnpm exec wrangler deploy'
deny 'pnpm wrangler deploy'
deny 'yarn dlx wrangler publish'
deny 'bunx wrangler versions upload'
deny 'wrangler versions deploy'
deny 'wrangler rollback'
deny 'wrangler secret put API_KEY'
deny 'wrangler login'
deny 'npx wrangler logout'
deny 'wrangler pages deploy dist'
deny 'wrangler d1 migrations apply DB --remote'
deny 'wrangler d1 execute DB --command "select 1"'
deny 'wrangler d1 create mydb'
deny 'wrangler kv key put k v'
deny 'wrangler r2 bucket create b'
deny 'wrangler dev --remote'
deny './node_modules/.bin/wrangler deploy'

# Wrappers, chains, and substitutions.
deny 'cd app && npx wrangler deploy'
deny 'npm test; wrangler deploy'
deny 'echo $(wrangler deploy)'
deny 'echo "$(npx wrangler deploy)"'
deny 'bash -c "wrangler deploy"'
deny "sh -c 'cd app && wrangler deploy'"
deny 'eval "wrangler deploy"'
deny 'CLOUDFLARE_ENV=prod wrangler deploy'
deny 'sudo wrangler deploy'
deny 'env FOO=1 wrangler deploy'
deny 'if true; then wrangler deploy; fi'

# Other CLIs.
deny 'vercel'
deny 'vercel --prod'
deny 'npx vercel deploy'
deny 'vercel env add SECRET'
deny 'netlify deploy --prod'
deny 'firebase deploy'
deny 'firebase hosting:channel:deploy preview'
deny 'fly deploy'
deny 'gcloud run deploy svc'
deny 'gcloud auth login'
deny 'aws s3 sync dist s3://bucket'
deny 'aws lambda update-function-code --function-name f'
deny 'az login'
deny 'supabase db push'
deny 'supabase functions deploy hello'
deny 'supabase secrets set KEY=v'
deny 'terraform apply'
deny 'terraform destroy -auto-approve'
deny 'pulumi up'
deny 'cdk deploy'
deny 'kubectl apply -f k8s.yaml'
deny 'helm upgrade app chart'
deny 'gh secret set TOKEN'
deny 'docker push img:latest'

# Package publishing.
deny 'npm publish'
deny 'pnpm publish --access public'
deny 'yarn npm publish'
deny 'cargo publish'
deny 'twine upload dist/*'
deny 'uv publish'
deny 'npx changeset publish'
deny 'npx semantic-release'

# Scripts, make targets, and files with deploy-like names.
deny 'npm run deploy'
deny 'pnpm run deploy:prod'
deny 'yarn release'
deny 'bun run publish-site'
deny 'npm run ship' "$fixture/app"
deny 'npm run go' "$fixture/app"
deny 'pnpm migrate' "$fixture/app"
deny 'npm --prefix app run ship'
deny 'cd app && npm run ship'
deny 'npm start' "$fixture/site"
deny 'make deploy'
deny 'just release'
deny './scripts/deploy.sh'
deny 'bash scripts/deploy-prod.sh'
deny 'node scripts/publish.mjs'

# Local and read-only commands pass.
pass 'wrangler dev'
pass 'npx wrangler dev --port 8787'
pass 'wrangler deploy --dry-run'
pass 'wrangler deploy --dry-run --outdir dist'
pass 'wrangler versions upload --dry-run'
pass 'wrangler types'
pass 'wrangler --version'
pass 'npx wrangler --help'
pass 'wrangler deploy --help'
pass 'wrangler whoami'
pass 'wrangler tail'
pass 'wrangler d1 execute DB --local --command "select 1"'
pass 'wrangler d1 migrations apply DB --local'
pass 'wrangler d1 migrations create DB init'
pass 'vercel dev'
pass 'vercel --version'
pass 'terraform plan'
pass 'gcloud config set project p'
pass 'npm install'
pass 'npm run dev' "$fixture/app"
pass 'npm run build' "$fixture/app"
pass 'npm run check' "$fixture/app"
pass 'npm test' "$fixture/app"
pass 'pnpm dev' "$fixture/app"
pass 'pnpm wrangler' "$fixture/app"
pass 'npm run lint' "$fixture/app"
pass 'make test'
pass 'ls -la'
pass 'git status'
pass 'git commit -m "Add wrangler deploy guard; block npm run deploy"'
pass 'grep -rn "wrangler deploy" docs'
pass 'echo wrangler deploy'
pass "git commit -F - <<'EOF'
feat: add deploy guard

wrangler deploy
\`npm run deploy\`
EOF"
pass 'bash hooks/deploy-guard.sh < input.json'
pass 'git log --oneline | head -5'

# Billing guard: local wrangler commands are no longer asked about.
for c in 'wrangler dev' 'npx wrangler dev --port 8787' 'wrangler deploy --dry-run' 'wrangler types' \
  'wrangler --version' 'wrangler d1 execute DB --local --command "select 1"'; do
  expect billing-guard.sh none "$c"
done
for c in 'wrangler whoami' 'wrangler tail' 'wrangler dev --remote' 'wrangler deploy' \
  'wrangler dev && wrangler d1 list' 'pip install anthropic' 'gcloud compute instances list'; do
  expect billing-guard.sh ask-or-deny "$c"
done

printf '%d checks, %d failed\n' "$count" "$fail"
[ $fail = 0 ]
