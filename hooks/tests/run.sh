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

mkdir -p "$fixture/home"
hook_home=$fixture/home

# Runs a hook with a clean environment and a fixture home, so credentials on
# this machine do not change the result. TOOL selects the tool (default Bash).
decision() { # hook mode command [cwd]
  jq -nc --arg t "${TOOL:-Bash}" --arg m "$2" --arg c "$3" --arg d "${4:-$fixture}" \
    '{tool_name:$t,permission_mode:$m,cwd:$d,tool_input:(if $t == "Bash" or ($t | endswith("run_in_terminal")) then {command:$c} else ($c | fromjson) end)}' |
    env -i PATH="$PATH" HOME="$hook_home" /bin/bash "$hooks/$1" | jq -r '.hookSpecificOutput.permissionDecision // empty'
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

# Billing guard fixtures: scripts, manifests, and homes with credentials.
mkdir -p "$fixture/py" "$fixture/py2" "$fixture/node" "$fixture/envapp" "$fixture/keyhome" \
  "$fixture/credhome/.aws" "$fixture/allowhome/.claude"
printf 'import anthropic\nanthropic.Anthropic()\n' >"$fixture/app/call.py"
printf 'print("hello")\n' >"$fixture/app/plain.py"
printf 'const OpenAI = require("openai");\n' >"$fixture/app/call.js"
printf '#!/bin/sh\ncurl https://api.openai.com/v1/models\n' >"$fixture/app/fetch.sh"
printf '#!/bin/sh\necho build\n' >"$fixture/app/build.sh"
printf '[project]\nname = "p"\ndependencies = [\n  "openai>=1.0",\n]\n' >"$fixture/py/pyproject.toml"
printf '[project]\nname = "p"\ndescription = "Work together with replicate steps"\ndependencies = ["numpy"]\n' >"$fixture/py2/pyproject.toml"
printf 'anthropic==0.40\n' >"$fixture/py2/requirements-ai.txt"
printf '{ "dependencies": { "@anthropic-ai/sdk": "^0.30.0" }, "scripts": { "seed": "node ../app/call.js" } }\n' >"$fixture/node/package.json"
printf 'ANTHROPIC_API_KEY=test\n' >"$fixture/envapp/.env"
printf 'export OPENAI_API_KEY=test\n' >"$fixture/keyhome/.zshrc"
printf '[default]\n' >"$fixture/credhome/.aws/credentials"
printf '# trusted servers\nmy-docs\n' >"$fixture/allowhome/.claude/billing-guard-mcp-allowlist"

bill() { expect billing-guard.sh "$@"; }
mcp() { # expected tool input-json
  TOOL=$2 expect billing-guard.sh "$1" "$3"
}

# Local wrangler commands pass; other cloud CLI use is asked about.
for c in 'wrangler dev' 'npx wrangler dev --port 8787' 'wrangler deploy --dry-run' 'wrangler types' \
  'wrangler --version' 'wrangler d1 execute DB --local --command "select 1"'; do
  bill none "$c"
done
for c in 'wrangler whoami' 'wrangler tail' 'wrangler dev --remote' 'wrangler deploy' \
  'wrangler dev && wrangler d1 list' 'gcloud compute instances list' 'npx -y vercel@latest dev' \
  'stripe products create --name x' 'modal run app.py' 'supabase projects create demo' 'terraform apply'; do
  bill ask-or-deny "$c"
done

# Paid SDK packages, also through runners and manifests.
for c in 'pip install anthropic' 'pip3 install "openai>=1"' 'uv add litellm' 'uv pip install boto3' \
  'python3 -m pip install google-genai' 'npm i @anthropic-ai/sdk' 'pnpm add @ai-sdk/openai' 'yarn add stripe' \
  'npx -y aider-chat' 'uvx llm hello' 'uv run --with openai python -V' 'pipx run --spec openai openai' \
  'brew install stripe/stripe-cli/stripe' 'pip install -r requirements-ai.txt'; do
  bill ask-or-deny "$c" "$fixture/py2"
done
bill ask-or-deny 'uv sync' "$fixture/py"
bill ask-or-deny 'cd py && uv sync'
bill ask-or-deny 'npm install' "$fixture/node"
bill none 'uv sync' "$fixture/py2"
bill none 'npm install' "$fixture/app"
bill none 'brew install uv ffmpeg'
bill none 'npx prettier --write docs/replicate-steps.md'
bill none 'npm i && echo "built together"'
bill none 'brew install jq && cat notes/groq.md'

# Code passed to an interpreter is checked; text for text commands is not.
bill ask-or-deny "python3 -c 'import anthropic; anthropic.Anthropic()'"
bill ask-or-deny "node -e \"fetch('https://api.openai.com/v1/models')\""
bill ask-or-deny 'curl https://api.anthropic.com/v1/messages'
bill ask-or-deny 'curl https://api.elevenlabs.io/v1/voices'
bill ask-or-deny "python3 - <<'EOF'
from openai import OpenAI
OpenAI()
EOF"
bill ask-or-deny "bash -c 'curl https://api.openai.com/v1/models'"
bill ask-or-deny 'python3 call.py' "$fixture/app"
bill ask-or-deny 'node call.js' "$fixture/app"
bill ask-or-deny './fetch.sh' "$fixture/app"
bill ask-or-deny 'npm run seed' "$fixture/node"
bill ask-or-deny 'python3 missing.py' "$fixture/app"
bill ask-or-deny 'echo Y3VybA== | base64 -d | sh'
bill ask-or-deny 'cat x.py | python3'
bill ask-or-deny "cat > gen.py <<'EOF'
print(1)
EOF
python3 gen.py" "$fixture/app"
bill none 'python3 plain.py' "$fixture/app"
bill none './build.sh' "$fixture/app"
bill none 'python3 --version'
bill none "cd app >/dev/null; python3 - <<'EOF'
from pathlib import Path
text = '''
brew install uv ffmpeg
uv sync
To change both repositories together, run uvx or npx.
'''
Path('README.md').write_text(text)
EOF"
bill none "git commit -m 'docs: explain pip install openai and api.openai.com'"
bill none "grep -rn 'api.openai.com' src"
bill none "cat > x.md <<'EOF'
aws s3 ls
pip install anthropic
EOF"
bill none 'bash hooks/billing-guard.sh < input.json'

# AI tools, scheduling, and CI.
for c in 'aider --model x' 'llm "hello"' "(crontab -l; echo '* * * * * job') | crontab -" \
  'launchctl load ~/Library/LaunchAgents/x.plist' 'gh workflow run nightly.yml' 'gh codespace create'; do
  bill ask-or-deny "$c"
done
bill none 'crontab -l'
bill none 'gh pr view 1'

# Credentials for paid services: any code needs approval, text commands do not.
bill ask-or-deny 'export OPENAI_API_KEY=test; python3 plain.py' "$fixture/app"
bill ask-or-deny 'ANTHROPIC_API_KEY=test claude -p hi'
bill ask-or-deny 'python3 plain.py' "$fixture/envapp"
bill ask-or-deny 'cd envapp && npm test'
bill none 'git status' "$fixture/envapp"
hook_home=$fixture/keyhome
bill ask-or-deny 'python3 plain.py' "$fixture/app"
bill ask-or-deny 'make test'
bill none 'ls -la'
hook_home=$fixture/credhome
bill ask-or-deny 'node -v && node build.js'
hook_home=$fixture/home

# Commands typed into the Terminal panel get the same checks.
TOOL=mcp__terminal__run_in_terminal expect billing-guard.sh ask-or-deny 'pip install openai'
TOOL=mcp__terminal__run_in_terminal expect billing-guard.sh none 'npm run dev' "$fixture/app"

# MCP tools: billing, key, and limit pages are always denied.
for u in https://dash.cloudflare.com/abc/billing https://console.cloud.google.com/billing \
  https://claude.ai/upgrade https://platform.claude.com/settings/keys https://platform.claude.com/settings/limits \
  https://console.anthropic.com/settings/api-keys https://example.com/account/credits; do
  mcp deny mcp__Claude_Browser__navigate "{\"url\":\"$u\"}"
done
mcp deny mcp__claude-in-chrome__javascript_tool '{"action":"javascript_exec","text":"location.href = \"https://dash.cloudflare.com/x/billing\""}'
mcp deny mcp__cloud__upgrade_plan '{}'
mcp none mcp__Claude_Browser__navigate '{"url":"https://www.anthropic.com/pricing"}'
mcp none mcp__Claude_Browser__computer '{"action":"left_click","coordinate":[1,2]}'
mcp none mcp__ccd_session__mark_chapter '{"title":"x"}'
mcp none mcp__visualize__show_widget '{"widget_code":"<svg/>"}'

# MCP servers not on the allowlist, and scheduled tasks, need approval.
mcp ask-or-deny mcp__imagegen__generate_image '{"prompt":"cat"}'
mcp ask-or-deny mcp__my-docs__read '{"id":"1"}'
mcp ask-or-deny mcp__scheduled-tasks__create_scheduled_task '{"taskId":"x","prompt":"y","description":"z"}'
mcp none mcp__scheduled-tasks__list_scheduled_tasks '{}'
hook_home=$fixture/allowhome
mcp none mcp__my-docs__read '{"id":"1"}'
mcp ask-or-deny mcp__other-docs__read '{"id":"1"}'
hook_home=$fixture/home

printf '%d checks, %d failed\n' "$count" "$fail"
[ $fail = 0 ]
