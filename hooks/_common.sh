# shellcheck shell=bash
# Shared hook preamble. ADAPTED from the parent, with one substantive change: the phase is derived
# from an L-SERIES gate ledger. The parent's derivation matches G-F<n> rows and is blind to L0/L1,
# which is exactly why Lite gate rows live in this repo's ledger rather than the parent's.
export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin"
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# Bound to the FIRST COLUMN of rows that are both a phase gate and APPROVED. The parent learned
# this the hard way: its derivation read a heading that its own checkpoint hook WROTE, so the phase
# was self-sustaining and stayed three days past its gate (CR-014). Only the operator advances a
# gate ledger, so a ledger cannot self-feed. An unapproved row is not a phase this build reached.
PHASE=$(awk -F'|' '/APPROVED/ && $2 ~ /^ *L[0-9]+ *$/ {gsub(/[^0-9]/,"",$2); p=$2}
                   END{if(p!="") print "L" p}' "$ROOT/GATES.md" 2>/dev/null || true)
# Fails CLOSED to a sentinel. An empty phase field would be silently wrong in every audit line.
[ -n "${PHASE:-}" ] || PHASE="L?"

now () { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Redact by SHAPE first and truncate second — truncating first can sever a token and leave a usable
# prefix behind. Matches assignment and flag POSITIONS plus known credential prefixes, never bare
# mentions, so a rule file discussing these words stays readable while an actual value does not.
# Fails CLOSED: if the scrubber cannot run, emit a sentinel, because a lost audit target is
# recoverable and a leaked key is not.
# HARNESS-ROT-1: the truncation is now `head -c 400` — a bound on the WHOLE payload; the prior
# `cut -c1-200` was line-oriented, so a multi-line denied command logged essentially in full.
SCRUB_KEY='[A-Za-z0-9_.-]*(password|passwd|secret|token|api[_-]?key|access[_-]?key|secret[_-]?key|private[_-]?key|credentials?|client[_-]?secret|auth[_-]?token|authorization)[A-Za-z0-9_.-]*'
SCRUB_SEP="[\"']?[[:space:]]*[=:][[:space:]]*"
scrub () {
  _sc_in=${1:-}
  [ -n "$_sc_in" ] || { printf ''; return 0; }
  _sc_out=$(printf '%s' "$_sc_in" | sed -E \
    -e "s#(-----BEGIN[A-Z ]*PRIVATE KEY-----).*#\1[REDACTED]#g" \
    -e "s#([A-Za-z][A-Za-z0-9+.-]*://)[^/@[:space:]]+@#\1[REDACTED]@#g" \
    -e "s#(^|[^A-Za-z0-9_-])(gh[pousr]_|github_pat_|glpat-|xox[abopsr]-|sk-|sk_live_|pk_live_|AKIA|ASIA|AIza|ya29\.)[A-Za-z0-9_.-]{8,}#\1\2[REDACTED]#g" \
    -e "s#(^|[^A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]+#\1[REDACTED-JWT]#g" \
    -e "s#(bearer[[:space:]]+)[A-Za-z0-9._~+/=-]{6,}#\1[REDACTED]#gI" \
    -e "s#($SCRUB_KEY$SCRUB_SEP)\"[^\"]*\"#\1\"[REDACTED]\"#gI" \
    -e "s#($SCRUB_KEY$SCRUB_SEP)'[^']*'#\1'[REDACTED]'#gI" \
    -e "s#($SCRUB_KEY$SCRUB_SEP)[^[:space:]\"';|&\`]+#\1[REDACTED]#gI" \
    -e "s#(--?(password|passwd|token|api[_-]?key|secret|access[_-]?key|client[_-]?secret|auth[_-]?token)[[:space:]]+)[^[:space:]]+#\1[REDACTED]#gI" \
    2>/dev/null | head -c 400)
  if [ -z "$_sc_out" ]; then printf '%s' '[REDACTED-SCRUB-UNAVAILABLE]'; else printf '%s' "$_sc_out"; fi
}
# HARNESS-ROT-1: ONE notification dispatch table, every caller routes here (stop.sh, and in the
# parent notify.sh). The report's row-2 rot was stop.sh carrying half a private WSL-only copy of
# this table, so the toast died silently on macOS. A second copy of a dispatch table drifts.
toast () {
  _to_msg=${1:-}
  [ -n "$_to_msg" ] || return 0
  if grep -qi microsoft /proc/version 2>/dev/null && command -v wsl-notify-send.exe >/dev/null 2>&1; then
    wsl-notify-send.exe "psychic-crew-lite" "$_to_msg" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "psychic-crew-lite" "$_to_msg" >/dev/null 2>&1 || true
  elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$_to_msg\" with title \"psychic-crew-lite\"" >/dev/null 2>&1 || true
  fi
  return 0
}

# A PreToolUse denial is JSON on stdout; a bare exit 2 does NOT block. Emit both.
# The denial must leave its own record: PostToolUse never fires for a tool that was blocked, so a
# guard that does not write here blocks silently. The parent's G-F2 stress produced six live
# denials and zero audit entries for exactly this reason.
# The denied call is the WORST case for verbatim logging — the commands a guard blocks are the ones
# most likely to carry a credential — so the target is scrubbed on the way out.
deny () {
  { mkdir -p "$ROOT/logs"
    dt=$(printf '%s' "${INPUT:-}" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo unknown)
    dg=$(printf '%s' "${INPUT:-}" | jq -r '.tool_input.file_path // .tool_input.command // ""' 2>/dev/null || true)
    jq -cn --arg ts "$(now)" --arg t "$dt" --arg g "$(scrub "$dg")" \
           --arg r "$1" --arg p "$PHASE" \
       '{ts:$ts,event:"PreToolUse.deny",tool:$t,target:$g,reason:$r,phase:$p}' \
       >> "$ROOT/logs/deny-audit.jsonl"
  } >/dev/null 2>&1
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 2
}
