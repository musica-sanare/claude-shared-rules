#!/bin/bash
# PreToolUse hook enforcing rules/paid-services.md.
# - Bash: asks the owner before a command that may lead to paid or
#   usage-billed services, or blocks it where asking is impossible.
# - Other tools (browser, MCP): always blocks billing, plan, and payment pages
#   and tools, because only the owner changes plans or billing.
# Prints nothing and exits 0 when the call looks unrelated to billing.

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
  mode=$(printf '%s' "$input" | jq -r '.permission_mode // empty')
  if [ "$tool" = Bash ]; then
    text=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  else
    # Only URL fields, so text bodies (documents, messages) cannot match.
    text=$(printf '%s' "$input" | jq -r '[.tool_input | .. | objects | .url? // empty | strings] | join(" ")')
  fi
else
  tool=$(printf '%s' "$input" | grep -o '"tool_name" *: *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
  text=$input
fi
text=$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')
tool_lc=$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')

emit() { # decision reason
  local reason
  reason=$(printf '%s' "$2" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$reason"
  exit 0
}

if [ "$tool" != Bash ]; then
  billing_url_re='(billing|subscription|/upgrade|/plans?([/?#" ]|$)|payment|checkout|/purchase|/invoices?)'
  billing_tool_re='billing|subscription|payment|checkout|purchase|upgrade|invoice'
  if printf '%s' "$text" | grep -Eq "$billing_url_re" || printf '%s' "$tool_lc" | grep -Eq "$billing_tool_re"; then
    emit deny "Billing guard: this ${tool:-tool} call opens or changes billing, plans, or payments. Only the owner does that, in any permission mode. Do not retry or find another way; tell the owner what you wanted to check (rules/paid-services.md)."
  fi
  exit 0
fi

# Start of a shell command segment: line start, or after ; & | ( or $(,
# optionally through sudo or a package runner such as npx.
seg='(^|[;&|(]|\$\()[[:space:]]*(sudo[[:space:]]+)?((npx|pnpx|bunx|pnpm[[:space:]]+(exec|dlx)|yarn([[:space:]]+dlx)?|bun[[:space:]]+x|npm[[:space:]]+exec)([[:space:]]+-[^[:space:]]+)*[[:space:]]+)?'

install_re='(pip3?|uv|poetry|pipenv|conda|mamba|npm|pnpm|yarn|bun|gem|cargo|go|composer|brew)([[:space:]]+-[^[:space:]]+)*[[:space:]]+(install|add|i|get|require)([[:space:]]|$)|(npx|pnpx|bunx|uvx|pipx)[[:space:]]'
package_re='anthropic|claude-agent-sdk|openai|google-generativeai|google-genai|@google/genai|@google/generative-ai|vertexai|cohere|mistralai|groq|replicate|together|fireworks-ai|deepseek|boto3|aws-sdk|@aws-sdk/|google-cloud-|@google-cloud/|firebase-admin|azure-|@azure/|stripe|twilio|sendgrid'
api_re='api\.anthropic\.com|api\.openai\.com|generativelanguage\.googleapis\.com|aiplatform\.googleapis\.com|cloudbilling\.googleapis\.com|bedrock-runtime|api\.cloudflare\.com|api\.mistral\.ai|api\.cohere\.(ai|com)|api\.groq\.com|openrouter\.ai|api\.together\.(xyz|ai)|api\.replicate\.com|api\.deepseek\.com|api\.x\.ai|api\.stripe\.com'
cloud_cli='(aws|gcloud|gsutil|bq|az|doctl|eksctl|firebase|vercel|netlify|fly|flyctl|heroku|railway|wrangler)'
cloud_re="${seg}${cloud_cli}(@[^[:space:]]+)?([[:space:]]|$)"
iac_re="${seg}(terraform[[:space:]]+(apply|import)|tofu[[:space:]]+apply|pulumi[[:space:]]+up|cdk[[:space:]]+deploy|sam[[:space:]]+deploy|(serverless|sls)[[:space:]]+deploy)"
# Only a whole command that just prints a cloud CLI's version or help is exempt.
readonly_re="^[[:space:]]*${cloud_cli}[[:space:]]+(--version|-v|--help|-h|help)[[:space:]]*$"

reasons=()
if printf '%s' "$text" | grep -Eq "$install_re" && printf '%s' "$text" | grep -Eq "$package_re"; then
  reasons+=("installs or runs a package for a paid AI or cloud service")
fi
if printf '%s' "$text" | grep -Eq "$api_re"; then
  reasons+=("references a paid or cloud API endpoint")
fi
if printf '%s' "$text" | grep -Eq "$cloud_re" && ! printf '%s' "$text" | grep -Eq "$readonly_re"; then
  reasons+=("runs a cloud or hosting CLI that can create billable resources")
fi
if printf '%s' "$text" | grep -Eq "$iac_re"; then
  reasons+=("applies infrastructure that can create billable resources")
fi

[ ${#reasons[@]} -eq 0 ] && exit 0

joined=$(printf '%s; ' "${reasons[@]}")

# "ask" reaches the owner only in modes that show permission prompts. Auto and
# bypass modes resolve it without the owner, so deny there instead.
case "$mode" in
  default|plan|acceptEdits)
    emit ask "Billing guard: this command ${joined%; }. Approve only if you intend to use this paid service (rules/paid-services.md)."
    ;;
  *)
    emit deny "Billing guard: this command ${joined%; }. Blocked because permission mode '${mode:-unknown}' cannot ask the owner. Do not retry or rewrite it. Tell the owner what the command does and why; the owner may run it with a ! command or switch to default permission mode (rules/paid-services.md)."
    ;;
esac
