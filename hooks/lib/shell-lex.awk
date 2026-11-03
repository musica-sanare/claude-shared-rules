# Splits shell text into simple-command segments, one per output line, words
# joined by SEP. Shared by deploy-guard.sh and billing-guard.sh.
# Quotes are removed and a newline inside a quoted word becomes NLW; ; & | ( )
# $( and backticks end a segment; command substitutions become segments of
# their own; comments are dropped. Heredoc bodies are dropped, unless BODY is
# set: then each body is printed after its line as BODY <n> BODY <text>, where
# <n> is the number of the segment that owns the heredoc (counting from 1) and
# newlines in <text> are NLW.
# Usage: awk -v SEP=... -v NLW=... [-v BODY=...] -f shell-lex.awk

function flushw() { if (inw) seg = (seg == "" ? w : seg SEP w); w = ""; inw = 0 }
function flushs() { flushw(); if (seg != "") { print seg; ns++ } seg = "" }
function push(t) { sp++; st[sp] = t; sq[sp] = q; q = "" }
function pop() { q = sq[sp]; sp--; if (q != "") inw = 1 }
{ s = s $0 "\n" }
END {
  n = length(s); q = ""; sp = 0; hn = 0; ns = 0; i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (q == "\047") { if (c == "\047") q = ""; else w = w (c == "\n" ? NLW : c); i++; continue }
    if (q == "\"") {
      if (c == "\\") {
        d = substr(s, i + 1, 1)
        if (d == "\n") { i += 2; continue }
        if (d ~ /[$`"\\]/) { w = w d; i += 2; continue }
        w = w c; i++; continue
      }
      if (c == "\"") { q = ""; i++; continue }
      if (c == "$" && substr(s, i + 1, 1) == "(") { flushs(); push("("); i += 2; continue }
      if (c == "`") { flushs(); push("`"); i++; continue }
      w = w (c == "\n" ? NLW : c); i++; continue
    }
    if (c == "\\") { d = substr(s, i + 1, 1); if (d != "\n") { w = w d; inw = 1 } i += 2; continue }
    if (c == "\047" || c == "\"") { q = c; inw = 1; i++; continue }
    if (c == " " || c == "\t") { flushw(); i++; continue }
    if (c == "#" && !inw) { while (i <= n && substr(s, i, 1) != "\n") i++; continue }
    if (c == "\n") {
      flushs(); i++
      for (h = 1; h <= hn; h++) {
        body = ""; first = 1
        while (i <= n) {
          e = index(substr(s, i), "\n")
          if (e == 0) { line = substr(s, i); i = n + 1 } else { line = substr(s, i, e - 1); i += e }
          sub(/^\t+/, "", line)
          if (line == hd[h]) break
          body = (first ? line : body NLW line); first = 0
        }
        if (BODY != "") print BODY ho[h] BODY body
      }
      hn = 0; continue
    }
    if (c == "<" && substr(s, i + 1, 1) == "<") {
      flushw()
      if (substr(s, i + 2, 1) == "<") { i += 3; continue }
      i += 2; if (substr(s, i, 1) == "-") i++
      while (substr(s, i, 1) ~ /[ \t]/) i++
      dl = ""
      while (i <= n) { d = substr(s, i, 1); if (d ~ /[ \t\n;&|<>()]/) break; if (d != "\047" && d != "\"" && d != "\\") dl = dl d; i++ }
      if (dl != "") { hd[++hn] = dl; ho[hn] = ns + 1 }
      continue
    }
    if (c == "$" && substr(s, i + 1, 1) == "(") { flushs(); push("("); i += 2; continue }
    if (c == "`") { flushs(); if (sp > 0 && st[sp] == "`") pop(); else push("`"); i++; continue }
    if (c == ")") { flushs(); if (sp > 0 && st[sp] == "(") pop(); i++; continue }
    if (c ~ /[;&|(]/) { flushs(); i++; continue }
    w = w c; inw = 1; i++
  }
  flushs()
}
