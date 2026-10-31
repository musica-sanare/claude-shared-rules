#!/bin/bash
# PreToolUse hook for Bash: asks the owner before any command that may lead
# to paid or usage-billed services, or blocks it where asking is impossible.
# Enforces rules/paid-services.md.
# Prints nothing and exits 0 when the command looks unrelated to billing.

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
else
  cmd=$input
fi
cmd=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')

# Start of a shell command segment: line start, or after ; & | ( or $(.
seg='(^|[;&|(]|\$\()[[:space:]]*(sudo[[:space:]]+)?'

install_re='(pip3?|uv|poetry|pipenv|conda|mamba|npm|pnpm|yarn|bun|gem|cargo|go|composer|brew)([[:space:]]+-[^[:space:]]+)*[[:space:]]+(install|add|i|get|require)([[:space:]]|$)|(npx|pnpx|bunx|uvx|pipx)[[:space:]]'
package_re='anthropic|claude-agent-sdk|openai|google-generativeai|google-genai|@google/genai|@google/generative-ai|vertexai|cohere|mistralai|groq|replicate|together|fireworks-ai|deepseek|boto3|aws-sdk|@aws-sdk/|google-cloud-|@google-cloud/|firebase-admin|azure-|@azure/|stripe|twilio|sendgrid'
api_re='api\.anthropic\.com|api\.openai\.com|generativelanguage\.googleapis\.com|aiplatform\.googleapis\.com|bedrock-runtime|api\.mistral\.ai|api\.cohere\.(ai|com)|api\.groq\.com|openrouter\.ai|api\.together\.(xyz|ai)|api\.replicate\.com|api\.deepseek\.com|api\.x\.ai|api\.stripe\.com'
cloud_cli='(aws|gcloud|gsutil|bq|az|doctl|eksctl|firebase|vercel|netlify|fly|flyctl|heroku|railway|wrangler)'
cloud_re="${seg}${cloud_cli}([[:space:]]|$)"
iac_re="${seg}(terraform[[:space:]]+(apply|import)|tofu[[:space:]]+apply|pulumi[[:space:]]+up|cdk[[:space:]]+deploy|sam[[:space:]]+deploy|(serverless|sls)[[:space:]]+deploy)"
# Only a whole command that just prints a cloud CLI's version or help is exempt.
readonly_re="^[[:space:]]*${cloud_cli}[[:space:]]+(--version|-v|--help|-h|help)[[:space:]]*$"

reasons=()
if printf '%s' "$cmd" | grep -Eq "$install_re" && printf '%s' "$cmd" | grep -Eq "$package_re"; then
  reasons+=("installs or runs a package for a paid AI or cloud service")
fi
if printf '%s' "$cmd" | grep -Eq "$api_re"; then
  reasons+=("references a paid API endpoint")
fi
if printf '%s' "$cmd" | grep -Eq "$cloud_re" && ! printf '%s' "$cmd" | grep -Eq "$readonly_re"; then
  reasons+=("runs a cloud or hosting CLI that can create billable resources")
fi
if printf '%s' "$cmd" | grep -Eq "$iac_re"; then
  reasons+=("applies infrastructure that can create billable resources")
fi

[ ${#reasons[@]} -eq 0 ] && exit 0

joined=$(printf '%s; ' "${reasons[@]}")

# "ask" reaches the owner only in modes that show permission prompts. Auto and
# bypass modes resolve it without the owner, so deny there instead.
if command -v jq >/dev/null 2>&1; then
  mode=$(printf '%s' "$input" | jq -r '.permission_mode // empty')
fi
case "$mode" in
  default|plan|acceptEdits)
    decision=ask
    reason="Billing guard: this command ${joined%; }. Approve only if you intend to use this paid service (rules/paid-services.md)."
    ;;
  *)
    decision=deny
    reason="Billing guard: this command ${joined%; }. Blocked because permission mode '${mode:-unknown}' cannot ask the owner. Do not retry or rewrite it. Tell the owner what the command does and why; the owner may run it with a ! command or switch to default permission mode (rules/paid-services.md)."
    ;;
esac

reason=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
exit 0
