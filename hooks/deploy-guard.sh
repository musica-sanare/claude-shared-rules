#!/bin/bash
# PreToolUse hook enforcing rules/deployment.md.
# Denies, in every permission mode, Bash commands that deploy or change remote
# resources: deploys, version uploads and rollbacks, secret changes, remote
# writes, cloud CLI logins, and package publishing. Package-manager scripts
# (npm, pnpm, yarn, bun) are looked up in package.json and checked as well;
# script, make target, and file names that look like a deploy are denied too.
# Prints nothing and exits 0 when the command looks unrelated.
# Written for bash 3.2, the /bin/bash on macOS.

set -f  # no globbing when splitting words
input=$(cat)
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
if [ $have_jq = 1 ]; then
  tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
  command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
else
  tool=$(printf '%s' "$input" | grep -o '"tool_name" *: *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
  command=$(printf '%s' "$input" | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' |
    awk '{ gsub(/\\n/, "\n"); gsub(/\\t/, "\t"); gsub(/\\"/, "\""); gsub(/\\\\/, "\\"); print }')
  cwd=
fi
[ "$tool" = Bash ] || exit 0
[ -n "$cwd" ] || cwd=$PWD

SEP=$'\037'  # between words of a segment
NLW=$'\036'  # a newline inside a quoted word

deny() { # reason
  local reason="Deploy guard: $1 Claude never runs this, in any permission mode, even with the owner's approval (rules/deployment.md). Do not retry, rewrite, or run it another way. Give the owner the exact command, what it does, and how to check the result; the owner runs it in their own terminal or with a ! command."
  if [ $have_jq = 1 ]; then
    jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  else
    reason=$(printf '%s' "$reason" | tr '\000-\037' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
  fi
  exit 0
}

lexer=$(cd "$(dirname "$0")" && pwd)/lib/shell-lex.awk
[ -r "$lexer" ] || deny "the shell lexer $lexer is missing, so the command cannot be checked."

lex() { printf '%s' "$1" | awk -v SEP="$SEP" -v NLW="$NLW" -f "$lexer"; }

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

shown() { # words... -> the command as text, for messages
  local text
  text=$(printf '%s ' "$@" | tr "$SEP$NLW" '  ')
  text=${text% }
  [ ${#text} -gt 160 ] && text="${text:0:160}..."
  printf '%s' "$text"
}

deploy_name_re='deploy|publish|release|rollback'

check_name() { # kind name shown
  local base
  base=$(lower "${2##*/}")
  case $base in *-guard.sh) return ;; esac
  if [[ $base =~ $deploy_name_re ]]; then
    deny "\`$3\` runs the $1 '$2', whose name looks like a deploy or publish step."
  fi
}

check_command() { # text dir depth
  local cur_dir=$2 depth=$3 line
  [ "$depth" -gt 4 ] && return
  while IFS= read -r line; do
    [ -n "$line" ] && check_segment "$line" "$depth"
  done <<EOF
$(lex "$1")
EOF
}

resolve_dir() { # path
  case $1 in
    '~') printf '%s' "$HOME" ;;
    '~/'*) printf '%s' "$HOME/${1#\~/}" ;;
    /*) printf '%s' "$1" ;;
    *) printf '%s' "$cur_dir/$1" ;;
  esac
}

script_body() { # dir name
  [ $have_jq = 1 ] && [ -f "$1/package.json" ] || return
  jq -r --arg n "$2" '.scripts[$n] // empty | strings' "$1/package.json" 2>/dev/null
}

has_script() { # dir name
  [ $have_jq = 1 ] && [ -f "$1/package.json" ] || return 1
  jq -e --arg n "$2" '.scripts | type == "object" and has($n)' "$1/package.json" >/dev/null 2>&1
}

check_script() { # dir name depth shown
  local s body
  check_name "package script" "$2" "$4"
  for s in "pre$2" "$2" "post$2"; do
    body=$(script_body "$1" "$s")
    [ -n "$body" ] && check_command "$body" "$1" $(($3 + 1))
  done
}

check_segment() { # line depth
  local -a w
  IFS="$SEP" read -ra w <<<"$1"
  local depth=$2 n=${#w[@]} i=0 word base cmd
  while [ $i -lt $n ]; do
    word=${w[$i]}
    case $word in
      [A-Za-z_]*=*) i=$((i + 1)) ;;
      sudo | doas | env | command | builtin | exec | nohup | time | nice | then | do | else | elif | if | while | until | '!' | '{' | '}' | xargs | caffeinate)
        i=$((i + 1))
        while [ $i -lt $n ] && [ "${w[$i]#-}" != "${w[$i]}" ]; do i=$((i + 1)); done
        ;;
      timeout | gtimeout)
        i=$((i + 1))
        while [ $i -lt $n ] && [ "${w[$i]#-}" != "${w[$i]}" ]; do i=$((i + 1)); done
        i=$((i + 1))
        ;;
      npx | pnpx | bunx)
        i=$((i + 1))
        while [ $i -lt $n ]; do
          case ${w[$i]} in
            -p | --package) i=$((i + 2)) ;;
            --) i=$((i + 1)); break ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      *) break ;;
    esac
  done
  [ $i -lt $n ] || return
  word=${w[$i]}
  base=${word##*/}
  cmd=${base%%@*}
  [ -n "$cmd" ] || cmd=$base
  cmd=$(lower "$cmd")
  local -a rest=("${w[@]:$((i + 1))}")
  local text
  text=$(shown "${w[@]:$i}")

  # Positional words (P) and flags (F), lowercased, each word framed by spaces.
  local a P=" " F=" "
  for a in "${rest[@]}"; do
    case $a in
      '>'* | '<'* | [0-9]'>'* | [0-9]'<'* | '&>'*) ;;
      -*) F="$F$a " ;;
      *) a=${a// /_}; a=${a//$NLW/_}; P="$P$a " ;;
    esac
  done
  P=$(lower "$P")
  F=$(lower "$F")

  case $cmd in
    cd)
      [ ${#rest[@]} -gt 0 ] && cur_dir=$(resolve_dir "${rest[0]}")
      return
      ;;
    bash | sh | zsh | dash | ksh)
      local j=0
      while [ $j -lt ${#rest[@]} ]; do
        case ${rest[$j]} in
          --*) ;;
          -*c*)
            check_command "${rest[$((j + 1))]//$NLW/$'\n'}" "$cur_dir" $((depth + 1))
            return
            ;;
          -*) ;;
          *) check_name "script" "${rest[$j]}" "$text"; return ;;
        esac
        j=$((j + 1))
      done
      return
      ;;
    eval)
      local joined
      joined=$(printf '%s ' "${rest[@]}")
      check_command "${joined//$NLW/$'\n'}" "$cur_dir" $((depth + 1))
      return
      ;;
    npm | pnpm | yarn | bun)
      check_package_manager "$cmd" "$depth" "$text" "${rest[@]}"
      return
      ;;
    make | gmake | just)
      local t
      for t in $P; do check_name "target" "$t" "$text"; done
      return
      ;;
    node | python | python3 | tsx | ts-node | deno | ruby | perl)
      local t k=0
      for t in $P; do
        [ $k -lt 2 ] && check_name "script" "$t" "$text"
        k=$((k + 1))
      done
      return
      ;;
  esac

  check_name "command" "$base" "$text"

  # Help and version output never changes anything.
  [[ $F =~ \ (--help|-h|--version)\  ]] && return
  [[ $P =~ ^\ help\  ]] && return

  check_rules "$text"
}

check_package_manager() { # pm depth shown args...
  local pm=$1 depth=$2 text=$3
  shift 3
  local -a args=("$@") pos=()
  local dir=$cur_dir n=$# j=0 a sub_index=-1
  while [ $j -lt $n ]; do
    a=${args[$j]}
    case $a in
      --prefix | -C | --dir | --cwd) dir=$(resolve_dir "${args[$((j + 1))]}"); j=$((j + 1)) ;;
      --prefix=* | --dir=* | --cwd=*) dir=$(resolve_dir "${a#*=}") ;;
      --filter | -F | -w | --workspace) j=$((j + 1)) ;;
      -*) ;;
      *)
        [ $sub_index -lt 0 ] && sub_index=$j
        pos+=("$a")
        ;;
    esac
    j=$((j + 1))
  done
  [ ${#pos[@]} -gt 0 ] || return
  local sub
  sub=$(lower "${pos[0]}")
  local -a after=("${args[@]:$((sub_index + 1))}")
  case $sub in
    publish | unpublish | login | logout | adduser | deprecate)
      deny "\`$text\` publishes to or signs in to a package registry."
      ;;
    npm)
      case $(lower "${pos[1]}") in
        publish | login | logout) deny "\`$text\` publishes to or signs in to a package registry." ;;
      esac
      return
      ;;
    run | run-script | rum | urn)
      [ ${#pos[@]} -gt 1 ] && check_script "$dir" "${pos[1]}" "$depth" "$text"
      return
      ;;
    exec | x | dlx)
      check_segment "npx$SEP$(printf "%s$SEP" "${after[@]}")" $((depth + 1))
      return
      ;;
  esac
  if [ "$pm" = npm ]; then
    case $sub in
      start | stop | restart | test | t | tst) check_script "$dir" "${pos[0]}" "$depth" "$text" ;;
    esac
    return
  fi
  if has_script "$dir" "${pos[0]}"; then
    check_script "$dir" "${pos[0]}" "$depth" "$text"
    return
  fi
  case $pm:$sub in
    *:add | *:install | *:i | *:remove | *:rm | *:update | *:up | *:upgrade | *:link | *:unlink | *:init | *:create | \
      *:outdated | *:audit | *:why | *:list | *:ls | *:info | *:config | *:cache | *:store | *:prune | *:rebuild | \
      *:patch | *:import | *:fetch | *:env | *:licenses | *:bin | *:root | *:doctor | *:setup | *:workspaces | \
      *:workspace | *:pm | *:build | bun:test | bun:a | pnpm:uninstall | pnpm:un | pnpm:ln | pnpm:rb | \
      yarn:constraints | yarn:plugin | yarn:set | yarn:node)
      return
      ;;
  esac
  case $sub in
    start | test | stop | restart) check_name "package script" "${pos[0]}" "$text"; return ;;
  esac
  # pnpm, yarn, and bun run a package binary when no script has that name.
  check_segment "npx$SEP$(printf "%s$SEP" "${args[@]:$sub_index}")" $((depth + 1))
}

# A rule matches when the segment's command is one of CMDS, its positional
# words (P) match MATCH and not SKIP, its flags (F) match NEED, and its flags
# do not match UNLESS. P and F frame each word with spaces.
rule() { # cmds match [skip] [need] [unless]
  [[ " $1 " == *" $cmd "* ]] || return 0
  [[ $P =~ $2 ]] || return 0
  [ -n "$3" ] && [[ $P =~ $3 ]] && return 0
  [ -n "$4" ] && ! [[ $F =~ $4 ]] && return 0
  [ -n "$5" ] && [[ $F =~ $5 ]] && return 0
  deny "\`$text\` deploys, publishes, signs in, or changes remote resources."
}

check_rules() { # shown
  local text=$1

  # Cloudflare. Resource commands without --local may write to the account.
  rule wrangler ' (deploy|publish|upload) ' '' '' ' --dry-run[ =]'
  rule wrangler ' (rollback|login|logout|secret|secret:bulk|secrets-store) '
  rule wrangler ' (create|delete|rename|update|put|import|apply|execute|bulk|purge|trigger|set|unset|add|remove|attach|detach|enable|disable|pause|resume) ' \
    ' migrations create ' '' ' --local[ =]'
  rule wrangler '.' '' ' (--remote|-r)[ =]'

  # Other hosting and cloud CLIs.
  rule 'vercel vc' '.' '^ (dev|build|pull|ls|list|inspect|logs|whoami|env|domains|dns|certs|alias|project|projects|teams|init|switch|telemetry|open|bisect) '
  rule 'vercel vc' ' (add|rm|remove|delete|create|update|set|move|transfer|issue|buy|promote|rollback|redeploy|deploy|link|connect|disconnect|login|logout) '
  rule 'vercel vc' '.' '' ' --prod[ =]'
  rule 'netlify ntl' ' (deploy|login|logout|link|unlink|switch|init|api|[a-z:]+:(create|delete|set|unset|import|clone|deploy|publish)) '
  rule firebase ' (deploy|login|logout|[a-z:]*:(deploy|delete|set|unset|destroy|update|push|remove|create|clone|disable|enable|distribute|rollback|add|apply|import|restore|use|ci)) '
  rule 'fly flyctl' ' (deploy|launch|destroy|scale|restart|login|logout|signup|create|delete|set|unset|import|update|stop|start|run|clone|extend|attach|detach|suspend|resume|promote) '
  rule heroku ' (login|logout|create|destroy|[a-z:]*:(set|unset|create|destroy|delete|rollback|push|release|scale|add|remove|rm|restart|stop|transfer|promote|attach|detach|enable|disable)) '
  rule railway ' (up|deploy|redeploy|down|login|logout|delete|add|init|link) '
  rule railway ' variables ' '' ' --set[ =]'
  rule supabase ' (login|logout|link|unlink|push|deploy|repair|set|unset|cp|mv|rm|create|delete|update|activate|apply|enable|disable|remove|add|restore|pause|unpause) '
  rule supabase ' (reset|up) ' '' ' (--linked|--db-url)[ =]'
  rule gcloud ' (deploy|create|delete|update|patch|set-iam-policy|add-iam-policy-binding|remove-iam-policy-binding|enable|disable|rollback|import|submit|login|revoke|activate-service-account|cp|mv|rm|rsync|set|unset|add|remove|start|stop|restart|reset|resize|attach|detach|upload|publish|apply|execute|run|cancel) ' \
    '^ (config|components|help|info|topic) '
  rule gsutil ' (cp|mv|rm|rsync|mb|rb|setmeta|acl|defacl|iam|lifecycle|cors|web|versioning|label|retention|notification|compose|rewrite|hmac|kms) '
  rule bq ' (mk|rm|load|insert|update|cp|truncate|undelete|cancel|set-iam-policy|add-iam-policy-binding|remove-iam-policy-binding) '
  rule aws ' (create|delete|put|update|deploy|terminate|run|start|stop|reboot|modify|attach|detach|associate|disassociate|register|deregister|set|tag|untag|invoke|publish|send|upload|import|restore|enable|disable|cancel|replace|authorize|revoke|execute|reset|rotate|purge|copy|add|remove|apply|accept|reject|change|login)(-[^ ]*)? ' \
    '^ (configure|help) '
  rule aws ' s3 (cp|mv|rm|sync|mb|rb|website) '
  rule az ' (create|delete|update|set|deploy|up|start|stop|restart|login|logout|add|remove|import|upload|purge|publish|assign|grant|revoke|enable|disable|swap|scale|apply|invoke|run|cancel|reset|rotate|renew|attach|detach|move|copy|sync|upgrade|deallocate|redeploy|resize|reimage|put) ' \
    '^ (config|configure|extension|bicep|find|version|help) |^ account set '
  rule doctl ' (create|delete|update|deploy|apply|init|switch|rm|remove|add|upload|import|power-off|power-on|power-cycle|reboot|resize|rebuild|restore|attach|detach|enable|disable|purge|tag|untag|start|stop|cancel|revert|reset|flush|install|uninstall|upgrade|login|logout) '
  rule 'kubectl oc' ' (apply|create|delete|patch|replace|scale|autoscale|rollout|set|edit|label|annotate|drain|cordon|uncordon|taint|expose|run|cp|debug|certificate) ' \
    '^ (config|version|explain|completion|kustomize|plugin|help) '
  rule helm ' (install|upgrade|uninstall|delete|rollback|push|registry) ' \
    '^ (plugin|repo|dependency|dep|template|lint|package|show|search|version|completion|env|help) '
  rule gh ' (secret|variable) (set|delete|remove) '

  # Infrastructure as code.
  rule 'terraform tofu' ' (apply|destroy|import|taint|untaint|login|logout|force-unlock|push) '
  rule 'terraform tofu' ' (state (rm|mv|push|replace-provider)|workspace (new|delete)) '
  rule pulumi ' (up|update|destroy|refresh|import|cancel|login|logout|watch|deploy) '
  rule pulumi ' (stack|state) (rm|delete|init|rename|import|unprotect|edit|move|tag|transfer|change-secrets-provider) '
  rule pulumi ' env (set|rm|init|edit|rotate|tag|version) '
  rule cdk ' (deploy|destroy|bootstrap|import|watch|rollback|migrate|refactor|gc) '
  rule sam ' (deploy|delete|sync|publish|remote|pipeline) '
  rule 'serverless sls' ' (deploy|remove|rollback|login|logout|invoke|prune|reconcile) ' ' invoke local '

  # Containers and package registries.
  rule 'docker podman' ' (push|login|logout) '
  rule 'docker podman' ' build ' '' ' --push[ =]'
  rule cargo ' (publish|yank|owner|login|logout) '
  rule gem ' (push|yank|owner|signin|signout) '
  rule twine ' upload '
  rule 'poetry uv flit hatch pdm' ' publish '
  rule 'lerna changeset changesets' ' publish '
  rule np '.'
  rule 'vsce ovsx' ' (publish|unpublish|login|logout) '
  rule dotnet ' nuget push '
  rule 'mvn mvnw' ' (deploy|release:[a-z]+) '
  rule 'gradle gradlew' ' publish[^ ]* ' ' publish[a-z]*tomavenlocal '
  rule goreleaser '^ $| (release|publish) ' '' '' ' --snapshot[ =]'
  rule eas ' (submit|update|deploy|login|logout|[a-z]+:(create|delete|update|edit|push|rollout|promote)) '
  rule eas ' build ' '' '' ' --local[ =]'
  rule expo ' (publish|login|logout) '
}

check_command "$command" "$cwd" 0
exit 0
