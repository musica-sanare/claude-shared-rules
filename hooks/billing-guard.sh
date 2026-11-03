#!/bin/bash
# PreToolUse hook enforcing rules/paid-services.md. It fails safe: when a call
# may lead to a charge, it asks the owner, or blocks where asking is impossible.
# - Bash, and commands typed into the Terminal panel: asks before installing or
#   running paid AI or cloud SDKs and CLIs, calling paid API endpoints, running
#   code the guard cannot read, scheduling jobs, and running any code while
#   credentials for a paid service are available.
# - MCP tools: blocks billing, plan, payment, API key, and spending-limit pages
#   and tools in every mode; asks before tools of MCP servers that are not on
#   the allowlist and before scheduling tasks.
# Commands are split into segments by hooks/lib/shell-lex.awk, so text in
# quotes, commit messages, and heredocs for text commands does not match, while
# code passed to an interpreter is checked as code.
# Prints nothing and exits 0 when the call looks unrelated to billing.
# Written for bash 3.2, the /bin/bash on macOS.

set -f  # no globbing when splitting words
input=$(cat)
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

SEP=$'\037'   # between words of a segment
NLW=$'\036'   # a newline inside a word or heredoc body
BODY=$'\035'  # marks a heredoc body line from the lexer

emit() { # decision reason
  if [ $have_jq = 1 ]; then
    jq -nc --arg d "$1" --arg r "$2" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  else
    local reason
    reason=$(printf '%s' "$2" | tr '\000-\037' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$reason"
  fi
  exit 0
}

# "ask" reaches the owner only in modes that show permission prompts. Auto and
# bypass modes resolve it without the owner, so deny there instead.
ask_or_deny() { # what the call does
  case $mode in
    default | plan | acceptEdits)
      emit ask "Billing guard: this call $1. Approve only if you intend to use a paid service (rules/paid-services.md)."
      ;;
    *)
      emit deny "Billing guard: this call $1. Blocked because permission mode '${mode:-unknown}' cannot ask the owner. Do not retry or rewrite it. To write or edit a file, use the Edit or Write tool instead of a shell command. Otherwise tell the owner what the call does and why; the owner may run it with a ! command or switch to default permission mode (rules/paid-services.md)."
      ;;
  esac
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

if [ $have_jq = 1 ]; then
  tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
  mode=$(printf '%s' "$input" | jq -r '.permission_mode // empty')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
  command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty | strings')
  # Only URL fields, so text bodies (documents, messages) cannot match.
  urls=$(printf '%s' "$input" | jq -r '[.tool_input | .. | objects | .url? // empty | strings] | join(" ")')
  script=$(printf '%s' "$input" | jq -r '.tool_input.text // empty | strings')
else
  # Without jq the permission mode is unknown, so every match is denied.
  tool=$(printf '%s' "$input" | grep -o '"tool_name" *: *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
  mode=
  cwd=
  command=$(printf '%s' "$input" | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' |
    awk '{ gsub(/\\n/, "\n"); gsub(/\\t/, "\t"); gsub(/\\"/, "\""); gsub(/\\\\/, "\\"); print }')
  urls=$input
  script=
fi
[ -n "$cwd" ] || cwd=$PWD

# ---------------------------------------------------------------------------
# MCP tools

billing_url_re='(billing|subscription|/upgrade|/plans?([/?#" ]|$)|payment|checkout|/purchase|/invoices?|/api-?keys|/api_keys|/apikeys|/settings/keys|/limits([/?#" ]|$)|/credits|/spend|/budgets?([/?#" ]|$))'
billing_tool_re='billing|subscription|payment|checkout|purchase|upgrade|invoice|credit|api_?key|spend|budget'
# MCP servers whose tools may run without asking: tools of the Claude apps
# themselves. Add others, one server name per line, to the local allowlist.
allowed_servers=' Claude_Browser claude-in-chrome visualize terminal scheduled-tasks Claude_Code_iOS_Simulator mcp-registry remote-devices '
allowlist_file=$HOME/.claude/billing-guard-mcp-allowlist

server_allowed() { # server
  case $1 in ccd_*) return 0 ;; esac
  [[ $allowed_servers == *" $1 "* ]] && return 0
  [ -r "$allowlist_file" ] && sed 's/#.*//; s/[[:space:]]//g' "$allowlist_file" | grep -Fxq -- "$1"
}

check_mcp() {
  local tool_lc server text
  tool_lc=$(lower "$tool")
  server=${tool#mcp__}
  server=${server%%__*}
  text=$(lower "$urls")
  if [[ $tool_lc == *javascript* ]]; then
    text="$text $(lower "$script" | grep -oE 'https?://[^[:space:]"'\''`)]+' | tr '\n' ' ')"
  fi
  if printf '%s' "$text" | grep -Eq "$billing_url_re" || printf '%s' "$tool_lc" | grep -Eq "$billing_tool_re"; then
    emit deny "Billing guard: this ${tool:-tool} call opens or changes billing, plans, payments, API keys, or spending limits. Only the owner does that, in any permission mode. Do not retry or find another way; tell the owner what you wanted to check (rules/paid-services.md)."
  fi
  if [ "$server" = scheduled-tasks ] && [[ $tool_lc =~ (create|update|run)_scheduled_task ]]; then
    ask_or_deny "schedules Claude runs that this guard does not check when they happen"
  fi
  server_allowed "$server" ||
    ask_or_deny "uses the MCP server '$server', which is not on the billing guard's allowlist and may call a paid service. The owner can add a trusted server's name to $allowlist_file"
  exit 0
}

# ---------------------------------------------------------------------------
# Shell commands

reasons=()
flag() { # reason
  local r
  for r in "${reasons[@]}"; do [ "$r" = "$1" ] && return; done
  reasons+=("$1")
}

# Inside a script that is being checked, paths often hold variables, so an
# unreadable path or standard input there is not flagged.
in_file=0
flag_unread() { # reason
  [ $in_file -eq 0 ] && flag "$1"
}

paid_pkg_re='^(anthropic|claude-agent-sdk|claude-code|@anthropic-ai/.+|openai|@openai/.+|google-generativeai|google-genai|@google/genai|@google/generative-ai|@google/gemini-cli|vertexai|google-cloud-.+|@google-cloud/.+|cohere|cohere-ai|mistralai|@mistralai/.+|groq|groq-sdk|replicate|together|together-ai|fireworks-ai|deepseek|boto3|botocore|aiobotocore|awscli|aws-sdk|@aws-sdk/.+|firebase-admin|azure-.+|@azure/.+|stripe|@stripe/.+|twilio|sendgrid|@sendgrid/.+|elevenlabs|@elevenlabs/.+|litellm|langchain-(openai|anthropic|google-genai|google-vertexai|aws|cohere|mistralai|groq|together|fireworks)|@langchain/(openai|anthropic|google-genai|google-vertexai|aws|cohere|mistralai|groq)|@ai-sdk/.+|ai|aider-chat|llm|shell-gpt)$'
api_re='api\.anthropic\.com|api\.openai\.com|\.openai\.azure\.com|generativelanguage\.googleapis\.com|aiplatform\.googleapis\.com|cloudbilling\.googleapis\.com|(texttospeech|speech|translation|vision)\.googleapis\.com|bedrock-runtime|api\.cloudflare\.com|api\.mistral\.ai|api\.cohere\.(ai|com)|api\.groq\.com|openrouter\.ai|api\.together\.(xyz|ai)|api\.replicate\.com|api\.deepseek\.com|api\.x\.ai|api\.perplexity\.ai|api\.fireworks\.ai|api\.elevenlabs\.io|api\.stability\.ai|api\.assemblyai\.com|api\.deepgram\.com|api-inference\.huggingface\.co|router\.huggingface\.co|api\.runpod\.|api\.stripe\.com|api\.twilio\.com|api\.sendgrid\.com'
py_sdk='anthropic|claude_agent_sdk|openai|google\.generativeai|google\.genai|vertexai|google\.cloud|cohere|mistralai|groq|replicate|together|fireworks|deepseek|boto3|botocore|aiobotocore|firebase_admin|azure|stripe|twilio|sendgrid|elevenlabs|litellm|langchain_(openai|anthropic|google_genai|google_vertexai|aws|cohere|mistralai|groq|together|fireworks)'
js_sdk='@anthropic-ai/|openai|@google/genai|@google/generative-ai|@google-cloud/|@aws-sdk/|aws-sdk|firebase-admin|@azure/|stripe|twilio|@sendgrid/|cohere-ai|@mistralai/|groq-sdk|replicate|together-ai|@ai-sdk/|ai|elevenlabs|@elevenlabs/|@langchain/(openai|anthropic|google-genai|google-vertexai|aws)'
code_re="(^|[^a-z0-9_.])(import|from)[[:space:]]+($py_sdk)([^a-z0-9_]|\$)|from[[:space:]]+google[[:space:]]+import[[:space:]]+genai|(require|import)[[:space:]]*\(?[[:space:]]*['\"\`]($js_sdk)['\"\`/]|from[[:space:]]+['\"\`]($js_sdk)['\"\`/]|(anthropic|openai|gemini|google|mistral|cohere|groq|together|fireworks|deepseek|xai|openrouter|replicate|elevenlabs|stripe|aws|azure)_(api_key|api_token|secret_key|access_key_id)|$api_re"
key_name_re='^[A-Z0-9_]*(_API_KEY|_API_TOKEN|_SECRET_KEY|_ACCESS_KEY|_ACCESS_KEY_ID|_SECRET_ACCESS_KEY|_AUTH_TOKEN|_CLIENT_SECRET)$|^(GOOGLE_APPLICATION_CREDENTIALS|AWS_PROFILE|AWS_SESSION_TOKEN|HF_TOKEN|HUGGING_FACE_HUB_TOKEN)$'
cloud_cli=' aws gcloud gsutil bq az doctl eksctl firebase vercel vc netlify ntl fly flyctl heroku railway wrangler supabase stripe modal replicate runpodctl vastai hcloud linode-cli oci ibmcloud scw '
ai_cli=' aider llm sgpt codex gemini openai anthropic fabric mods chatgpt '
text_only=' echo printf git grep egrep fgrep rg ag ack cat head tail less more wc sort uniq diff cmp comm ls tree tee tr cut column fold fmt nl jq yq test [ [[ true false pwd basename dirname realpath readlink mkdir rmdir touch cp mv rm ln chmod chown stat file which type date sleep read set unset local return exit shift wait kill ps du df open pbcopy pbpaste tar zip unzip gzip gunzip shasum sha256sum md5 base64 hexdump od xxd iconv mktemp trap printenv id whoami hostname uname for case esac fi done function select in : '

# --- Credentials for paid services --------------------------------------------

keys=''
note_key() { # name source
  [[ $1 =~ $key_name_re ]] || return
  [[ ", $keys, " == *", $1 ($2), "* ]] && return
  keys="${keys:+$keys, }$1 ($2)"
}

keys_in_file() { # file label
  [ -r "$1" ] || return
  local name
  while IFS= read -r name; do [ -n "$name" ] && note_key "$name" "$2"; done <<EOF
$(sed -nE 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*[^[:space:]#].*/\2/p' "$1")
EOF
}

checked_dirs=' '
keys_in_dir() { # dir
  [[ $checked_dirs == *" $1 "* ]] && return
  checked_dirs="$checked_dirs$1 "
  local f
  for f in .env .env.local .env.development .env.production .dev.vars; do keys_in_file "$1/$f" "$f"; done
}

find_keys() {
  local name f
  while IFS= read -r name; do [ -n "$name" ] && note_key "$name" "environment"; done <<EOF
$(env | sed -nE 's/^([A-Za-z_][A-Za-z0-9_]*)=.+/\1/p')
EOF
  # The Bash tool's shell and the Terminal panel load the shell profile.
  for f in .zshenv .zshrc .zprofile .bashrc .bash_profile .profile; do keys_in_file "$HOME/$f" "~/$f"; done
  for f in .aws/credentials .config/gcloud/application_default_credentials.json .azure/msal_token_cache.json \
    .config/llm/keys.json Library/Preferences/.wrangler/config/default.toml .wrangler/config/default.toml \
    .config/.wrangler/config/default.toml; do
    [ -e "$HOME/$f" ] && keys="${keys:+$keys, }~/$f"
  done
  keys_in_dir "$cwd"
}

# --- Helpers -------------------------------------------------------------------

resolve() { # path
  case $1 in
    '~') printf '%s' "$HOME" ;;
    '~/'*) printf '%s' "$HOME/${1#\~/}" ;;
    /*) printf '%s' "$1" ;;
    *) printf '%s' "$cur_dir/$1" ;;
  esac
}

pkg_name() { # spec -> lowercase package name without version or extras
  local p
  p=$(lower "$1")
  p=${p#node_modules/}
  p=${p#npm:}
  case $p in
    @*/*@*) p=${p%@*} ;;
    @*) ;;
    *) p=${p%%@*} ;;
  esac
  p=${p%%[<>=~!;[ ]*}
  printf '%s' "$p"
}

check_pkg() { # spec
  local p
  p=$(pkg_name "$1")
  [[ $p =~ $paid_pkg_re ]] && flag "installs or runs the package '$p' for a paid AI or cloud service"
}

scan_manifest() { # file
  [ -r "$1" ] || return
  local t
  while IFS= read -r t; do
    [ -n "$t" ] && check_pkg "$t"
  done <<EOF
$(tr '[:upper:]' '[:lower:]' <"$1" | sed 's/#.*$//' | grep -oE '(^[[:space:]]*|["'\''])[@a-z0-9][@a-z0-9._/-]*' | sed -E 's/^[[:space:]"'\'']*//' | sort -u)
EOF
}

scan_manifests() { # dir family
  local f
  if [ "$2" = python ]; then
    for f in pyproject.toml requirements.txt Pipfile environment.yml uv.lock poetry.lock Pipfile.lock; do scan_manifest "$1/$f"; done
  else
    for f in package.json package-lock.json pnpm-lock.yaml yarn.lock; do scan_manifest "$1/$f"; done
  fi
}

check_code() { # code
  local code
  code=$(lower "$1" | tr "$NLW" '\n')
  printf '%s' "$code" | grep -Eq "$code_re" &&
    flag "runs code that uses a paid AI or cloud SDK, API key, or API endpoint"
}

# Checks a script file the command runs: shell scripts as commands, anything
# else as code. A script that does not exist yet (written by the same command)
# cannot be read, so it is flagged. The guard hooks themselves are skipped.
check_file() { # path depth
  local f
  f=$(resolve "$1")
  case ${f##*/} in *-guard.sh) return ;; esac
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    flag_unread "runs the script '$1', which the guard cannot read"
    return
  fi
  [ "$(wc -c <"$f")" -gt 1048576 ] && { flag "runs the script '$1', which is too large to check"; return; }
  grep -Iq . "$f" || return 0
  case $f in
    *.sh | *.bash | *.zsh) check_shell_file "$f" "$2" ;;
    *.py | *.js | *.mjs | *.cjs | *.ts | *.mts | *.cts | *.tsx | *.jsx | *.rb | *.pl | *.php) check_code "$(cat "$f")" ;;
    *)
      if head -1 "$f" | grep -Eq '^#!.*[/ ](ba|z|da|k)?sh([[:space:]]|$)'; then
        check_shell_file "$f" "$2"
      else
        check_code "$(cat "$f")"
      fi
      ;;
  esac
}

check_shell_file() { # path depth
  in_file=$((in_file + 1))
  check_command "$(cat "$1")" $(($2 + 1))
  in_file=$((in_file - 1))
}

script_body() { # dir name
  [ $have_jq = 1 ] && [ -f "$1/package.json" ] || return
  jq -r --arg n "$2" '.scripts[$n] // empty | strings' "$1/package.json" 2>/dev/null
}

check_script() { # dir name depth
  local s body
  for s in "pre$2" "$2" "post$2"; do
    body=$(script_body "$1" "$s")
    [ -n "$body" ] && check_command "$body" $(($3 + 1))
  done
}

# --- Command checks ------------------------------------------------------------

check_command() { # text depth
  local depth=$2 line rest owner ns=0 k=1
  local -a segs bodies
  [ "$depth" -gt 4 ] && { flag "nests commands too deeply to check"; return; }
  while IFS= read -r line; do
    case $line in
      "$BODY"*)
        rest=${line#"$BODY"}
        owner=${rest%%"$BODY"*}
        bodies[$owner]="${bodies[$owner]}${rest#*"$BODY"}$NLW"
        ;;
      ?*) ns=$((ns + 1)); segs[$ns]=$line ;;
    esac
  done <<EOF
$(printf '%s' "$1" | awk -v SEP="$SEP" -v NLW="$NLW" -v BODY="$BODY" -f "$lexer")
EOF
  while [ $k -le $ns ]; do
    check_segment "${segs[$k]}" "${bodies[$k]}" "$depth"
    k=$((k + 1))
  done
}

check_segment() { # line body depth
  local -a w
  IFS="$SEP" read -ra w <<<"$1"
  local n=${#w[@]} i=0
  while [ $i -lt $n ]; do
    case ${w[$i]} in
      [A-Za-z_]*=*) note_key "${w[$i]%%=*}" "set in the command"; i=$((i + 1)) ;;
      sudo | doas | env | command | builtin | exec | nohup | time | nice | then | do | else | elif | if | while | until | '!' | '{' | '}' | xargs | caffeinate | stdbuf | noglob | nocorrect)
        i=$((i + 1))
        while [ $i -lt $n ] && [ "${w[$i]#-}" != "${w[$i]}" ]; do i=$((i + 1)); done
        ;;
      timeout | gtimeout)
        i=$((i + 1))
        while [ $i -lt $n ] && [ "${w[$i]#-}" != "${w[$i]}" ]; do i=$((i + 1)); done
        i=$((i + 1))
        ;;
      *) break ;;
    esac
  done
  [ $i -lt $n ] || return
  run_words "$2" "$3" "${w[@]:$i}"
}

has_flag() { # pattern words... -> true if a word matches pattern exactly
  local pat=$1 a
  shift
  for a in "$@"; do [[ $a =~ ^($pat)$ ]] && return 0; done
  return 1
}

# Runs the checks for one simple command. Anything that is not a known
# text-only command counts as running code, which needs the owner's approval
# while credentials for a paid service are available.
run_words() { # body depth word args...
  local body=$1 depth=$2 word=$3
  shift 3
  local -a args=("$@")
  local base=${word##*/} cmd
  cmd=$(lower "${base%%@*}")
  [ -n "$cmd" ] || cmd=$(lower "$base")

  case $cmd in
    cd)
      [ ${#args[@]} -gt 0 ] && cur_dir=$(resolve "${args[0]}")
      keys_in_dir "$cur_dir"
      return
      ;;
    export | declare | typeset)
      local a
      for a in "${args[@]}"; do [[ $a == *=* ]] && note_key "${a%%=*}" "set in the command"; done
      return
      ;;
    find)
      local j=0
      while [ $j -lt ${#args[@]} ]; do
        case ${args[$j]} in
          -exec | -execdir | -ok | -okdir)
            local -a sub=()
            j=$((j + 1))
            while [ $j -lt ${#args[@]} ] && [ "${args[$j]}" != ';' ] && [ "${args[$j]}" != '+' ]; do
              sub+=("${args[$j]}")
              j=$((j + 1))
            done
            [ ${#sub[@]} -gt 0 ] && run_words "" "$depth" "${sub[@]}"
            ;;
        esac
        j=$((j + 1))
      done
      return
      ;;
  esac

  [[ $text_only == *" $cmd "* ]] && return
  [ ${#args[@]} -eq 1 ] && has_flag '--version|-v|-V|--help|-h' "${args[@]}" && return

  # Everything below runs code or reaches the network.
  [ -n "$keys" ] && flag "runs code while credentials for a paid service are available: $keys"

  case $cmd in
    bash | sh | zsh | dash | ksh) run_shell "$body" "$depth" "${args[@]}" ;;
    eval)
      local joined
      joined=$(printf '%s ' "${args[@]}")
      check_command "${joined//$NLW/$'\n'}" $((depth + 1))
      ;;
    source | .) [ ${#args[@]} -gt 0 ] && check_file "${args[0]}" "$depth" ;;
    python | python3 | python3.* | python2 | pypy | pypy3) run_python "$body" "$depth" "${args[@]}" ;;
    node | nodejs | deno | tsx | ts-node | ruby | perl | php | osascript) run_interpreter "$cmd" "$body" "$depth" "${args[@]}" ;;
    pip | pip3 | uv | poetry | pipenv | pdm | rye | hatch | conda | mamba | micromamba | pipx | uvx) run_python_pm "$cmd" "$depth" "${args[@]}" ;;
    npm | pnpm | yarn | bun) run_node_pm "$cmd" "$depth" "${args[@]}" ;;
    npx | pnpx | bunx) run_npx "$depth" "${args[@]}" ;;
    gem | cargo | go | composer | brew)
      if [ ${#args[@]} -gt 1 ] && [[ ${args[0]} =~ ^(install|add|get|require|i)$ ]]; then
        local a
        for a in "${args[@]:1}"; do [ "${a#-}" = "$a" ] && check_pkg "${a##*/}"; done
      fi
      ;;
    curl | wget | http | https | xh | httpie | aria2c)
      printf '%s' "$(lower "${args[*]}")" | grep -Eq "$api_re" && flag "calls a paid or cloud API endpoint"
      ;;
    terraform | tofu | pulumi | cdk | sam | serverless | sls)
      [[ " $(lower "${args[*]}") " =~ \ (apply|import|destroy|up|update|deploy|sync)\  ]] &&
        flag "applies infrastructure that can create billable resources"
      ;;
    crontab)
      [ ${#args[@]} -eq 1 ] && [ "${args[0]}" = -l ] || flag "schedules jobs that run later without this guard"
      ;;
    launchctl | at | batch)
      [ "$cmd" = launchctl ] && [[ ${args[0]} =~ ^(list|print|help|version)$ ]] ||
        flag "schedules jobs that run later without this guard"
      ;;
    gh)
      [[ " $(lower "${args[*]}") " =~ \ (workflow\ run|run\ rerun|codespace\ (create|code|ssh|cp|ports|rebuild|jupyter))\  ]] &&
        flag "starts GitHub Actions or Codespaces, which can bill"
      ;;
    *)
      if [[ $cloud_cli == *" $cmd "* ]]; then
        run_cloud "$cmd" "${args[@]}"
      elif [[ $ai_cli == *" $cmd "* ]]; then
        flag "runs the AI tool '$cmd', which may call a paid API"
      elif [[ $word == */* ]]; then
        check_file "$word" "$depth"
      fi
      ;;
  esac
}

run_shell() { # body depth args...
  local body=$1 depth=$2 j=0
  shift 2
  local -a a=("$@")
  while [ $j -lt ${#a[@]} ]; do
    case ${a[$j]} in
      --*) ;;
      -*c*) check_command "${a[$((j + 1))]//$NLW/$'\n'}" $((depth + 1)); return ;;
      -*) ;;
      *) check_file "${a[$j]}" "$depth"; return ;;
    esac
    j=$((j + 1))
  done
  if [ -n "$body" ]; then
    check_command "${body//$NLW/$'\n'}" $((depth + 1))
  else
    flag_unread "runs shell code from standard input, which the guard cannot read"
  fi
}

run_python() { # body depth args...
  local body=$1 depth=$2 j=0 a
  shift 2
  local -a args=("$@")
  while [ $j -lt ${#args[@]} ]; do
    a=${args[$j]}
    case $a in
      -c) check_code "${args[$((j + 1))]}"; return ;;
      -m)
        local mod=${args[$((j + 1))]}
        case $mod in
          pip) run_python_pm pip "$depth" "${args[@]:$((j + 2))}" ;;
          *) check_pkg "${mod%%.*}"; [ -n "$body" ] && check_code "$body" ;;
        esac
        return
        ;;
      -W | -X) j=$((j + 1)) ;;
      -) break ;;
      -*) ;;
      *) run_code_arg "$a" "$depth"; return ;;
    esac
    j=$((j + 1))
  done
  if [ -n "$body" ]; then check_code "$body"; else flag_unread "runs code from standard input, which the guard cannot read"; fi
}

run_interpreter() { # cmd body depth args...
  local cmd=$1 body=$2 depth=$3 j=0 a
  shift 3
  local -a args=("$@")
  while [ $j -lt ${#args[@]} ]; do
    a=${args[$j]}
    case $a in
      -e | --eval | -E) check_code "${args[$((j + 1))]}"; return ;;
      -p | --print)
        if [ "$cmd" = node ] || [ "$cmd" = nodejs ]; then check_code "${args[$((j + 1))]}"; return; fi
        ;;
      eval)
        if [ "$cmd" = deno ]; then check_code "${args[$((j + 1))]}"; else run_code_arg "$a" "$depth"; fi
        return
        ;;
      run) [ "$cmd" = deno ] || { run_code_arg "$a" "$depth"; return; } ;;
      -) break ;;
      -*) ;;
      *) run_code_arg "$a" "$depth"; return ;;
    esac
    j=$((j + 1))
  done
  if [ -n "$body" ]; then check_code "$body"; else flag_unread "runs code from standard input, which the guard cannot read"; fi
}

# A script path, or code given as a word (a here-string).
run_code_arg() { # word depth
  if [[ $1 == *"$NLW"* || $1 == *' '* ]]; then
    check_code "$1"
  else
    check_file "$1" "$2"
  fi
}

run_python_pm() { # cmd depth args...
  local pm=$1 depth=$2 j=0 a dir=$cur_dir
  shift 2
  local -a args=("$@") pos=() reqs=()
  while [ $j -lt ${#args[@]} ]; do
    a=${args[$j]}
    case $a in
      -r | --requirement | --requirements | -c | --constraint | --with-requirements) reqs+=("${args[$((j + 1))]}"); j=$((j + 1)) ;;
      --with | --from | --spec) check_pkg "${args[$((j + 1))]}"; j=$((j + 1)) ;;
      --with=* | --from=* | --spec=*) check_pkg "${a#*=}" ;;
      --directory | --project | -C | --cwd) dir=$(resolve "${args[$((j + 1))]}"); j=$((j + 1)) ;;
      --env-file) keys_in_file "$(resolve "${args[$((j + 1))]}")" "${args[$((j + 1))]}"; j=$((j + 1)) ;;
      --python | -p | --index-url | -i | --extra-index-url | --index | --group | --extra | --package | -e | --editable | --with-editable) j=$((j + 1)) ;;
      -*) ;;
      *)
        pos+=("$a")
        if [ ${#pos[@]} -eq 1 ] && [ "$pm" = uvx ]; then
          check_pkg "$a"
          return
        fi
        # uv run and the run commands of other tools run the rest.
        if [ ${#pos[@]} -eq 2 ] && [ "${pos[0]}" = run ]; then
          if [ "$pm" = pipx ]; then
            check_pkg "$a"
          else
            local -a rest=("${args[@]:$j}")
            case ${rest[0]} in
              *.py) run_python "" "$depth" "${rest[@]}" ;;
              *) run_words "" "$depth" "${rest[@]}" ;;
            esac
          fi
          return
        fi
        if [ ${#pos[@]} -eq 3 ] && [ "${pos[0]}" = tool ] && [[ ${pos[1]} =~ ^(run|install)$ ]]; then
          check_pkg "$a"
          return
        fi
        ;;
    esac
    j=$((j + 1))
  done
  [ ${#pos[@]} -gt 0 ] || return
  local sub=${pos[0]} k=1
  if [ "$sub" = pip ]; then sub=${pos[1]}; k=2; fi
  case $sub in
    install | add | i | sync | update | upgrade | up | lock | inject) ;;
    *) return ;;
  esac
  local r
  for r in "${reqs[@]}"; do scan_manifest "$(resolve "$r")"; done
  if [ ${#pos[@]} -gt $k ]; then
    for a in "${pos[@]:$k}"; do check_pkg "$a"; done
  elif [ ${#reqs[@]} -eq 0 ]; then
    scan_manifests "$dir" python
  fi
}

run_node_pm() { # pm depth args...
  local pm=$1 depth=$2 j=0 a dir=$cur_dir sub_index=-1
  shift 2
  local -a args=("$@") pos=()
  while [ $j -lt ${#args[@]} ]; do
    a=${args[$j]}
    case $a in
      --prefix | -C | --dir | --cwd) dir=$(resolve "${args[$((j + 1))]}"); j=$((j + 1)) ;;
      --prefix=* | --dir=* | --cwd=*) dir=$(resolve "${a#*=}") ;;
      --filter | -F | -w | --workspace) j=$((j + 1)) ;;
      -*) ;;
      *) [ $sub_index -lt 0 ] && sub_index=$j; pos+=("$a") ;;
    esac
    j=$((j + 1))
  done
  if [ ${#pos[@]} -eq 0 ]; then
    # Bare pnpm, yarn, and bun install the project's dependencies.
    [ "$pm" = npm ] || scan_manifests "$dir" node
    return
  fi
  local sub
  sub=$(lower "${pos[0]}")
  case $sub in
    install | i | add | a | ci | update | upgrade | up)
      if [ ${#pos[@]} -gt 1 ]; then
        for a in "${pos[@]:1}"; do check_pkg "$a"; done
      else
        scan_manifests "$dir" node
      fi
      ;;
    run | run-script | rum | urn)
      if [ ${#pos[@]} -gt 1 ]; then
        if [ "$pm" = bun ] && [ -z "$(script_body "$dir" "${pos[1]}")" ]; then
          run_code_arg "${pos[1]}" "$depth"
        else
          check_script "$dir" "${pos[1]}" "$depth"
        fi
      fi
      ;;
    exec | x | dlx) run_npx "$depth" "${args[@]:$((sub_index + 1))}" ;;
    start | stop | restart | test | t | tst) check_script "$dir" "$sub" "$depth" ;;
    publish | unpublish | login | logout | remove | rm | uninstall | un | link | unlink | init | create | outdated | audit | why | list | ls | info | view | config | cache | store | prune | rebuild | patch | import | fetch | env | licenses | bin | root | doctor | setup | workspaces | workspace | pm | build | pack | version) ;;
    *)
      if [ -n "$(script_body "$dir" "${pos[0]}")" ]; then
        check_script "$dir" "${pos[0]}" "$depth"
      elif [ "$pm" = bun ] && [[ ${pos[0]} == *.* || ${pos[0]} == */* ]]; then
        run_code_arg "${pos[0]}" "$depth"
      elif [ "$pm" != npm ]; then
        # pnpm, yarn, and bun run a package binary when no script has that name.
        run_npx "$depth" "${args[@]:$sub_index}"
      fi
      ;;
  esac
}

run_npx() { # depth args...
  local depth=$1 j=0
  shift
  local -a args=("$@")
  while [ $j -lt ${#args[@]} ]; do
    case ${args[$j]} in
      -p | --package) check_pkg "${args[$((j + 1))]}"; j=$((j + 2)) ;;
      --package=*) check_pkg "${args[$j]#*=}"; j=$((j + 1)) ;;
      --) j=$((j + 1)); break ;;
      -*) j=$((j + 1)) ;;
      *) break ;;
    esac
  done
  [ $j -lt ${#args[@]} ] || return
  check_pkg "${args[$j]}"
  run_words "" "$depth" "${args[@]:$j}"
}

run_cloud() { # cmd args...
  local cmd=$1
  shift
  local lc
  lc=" $(lower "$*") "
  [[ $lc =~ ^\ (--version|-v|--help|-h|help)\ $ ]] && return
  if [ "$cmd" = wrangler ] && ! [[ $lc =~ \ (--remote|-r)(\ |=) ]]; then
    [[ $lc =~ ^\ (dev|types|docs)\  ]] && return
    [[ $lc =~ \ --(dry-run|local)(\ |=) ]] && return
  fi
  flag "runs the cloud or hosting CLI '$cmd', which can create billable resources"
}

# ---------------------------------------------------------------------------

case $tool in
  Bash | mcp__*__run_in_terminal) ;;
  mcp__*) check_mcp ;;
  *) exit 0 ;;
esac

lexer=$(cd "$(dirname "$0")" && pwd)/lib/shell-lex.awk
[ -r "$lexer" ] || emit deny "Billing guard: the shell lexer $lexer is missing, so the command cannot be checked. Tell the owner (rules/paid-services.md)."

cur_dir=$cwd
find_keys
check_command "$command" 0

[ ${#reasons[@]} -eq 0 ] && exit 0
joined=$(printf '%s; ' "${reasons[@]}")
ask_or_deny "${joined%; }"
