#!/usr/bin/env bash
# continuity.sh — the §6 mechanisms. One entry point because all four read the same event log.
#
#   heartbeat <agent> <state> [note]   record a self-reported state
#   stalls [--as <agent>]              detect stalls, NEVER from a single store
#   orient                             discover your own state from disk
#   seance <query>                     query the predecessor's EVENTS, not its summary
#
# STATED LIMIT: the event log lives in logs/, which is gitignored. These mechanisms are runtime
# state for a machine, not history that survives a clone. Seance answers "what did the previous
# session on this machine actually do", not "what happened on someone else's". The durable record
# is the ledgers and docs/verification-history.jsonl.
set -uo pipefail
cd "$(dirname "$0")/.."
HB="logs/heartbeats.jsonl"
STALE_S="${LITE_STALL_SECONDS:-900}"
AGENTS="session-orchestrator builder verifier security"
now () { date -u +%Y-%m-%dT%H:%M:%SZ; }
epoch_of () { date -u -d "$1" +%s 2>/dev/null || echo 0; }

phase_now () {
  awk -F'|' '/APPROVED/ && $2 ~ /^ *L[0-9]+ *$/ {gsub(/[^0-9]/,"",$2); p=$2}
             END{if(p!="") print "L" p; else print "L?"}' GATES.md 2>/dev/null
}

case "${1:-orient}" in

heartbeat)
  a="${2:?agent required}"; s="${3:?state required}"; n="${4:-}"
  case " $AGENTS " in *" $a "*) ;; *) echo "[FAIL] unknown agent '$a' (expected: $AGENTS)"; exit 64 ;; esac
  mkdir -p logs
  jq -cn --arg ts "$(now)" --arg a "$a" --arg s "$s" --arg n "$n" --arg p "$(phase_now)" \
     '{ts:$ts,event:"heartbeat",agent:$a,state:$s,note:$n,phase:$p}' >> "$HB"
  echo "  [ok] heartbeat $a=$s"
  ;;

stalls)
  by="${3:-verifier}"; [ "${2:-}" = "--as" ] || by="verifier"
  printf '== stall check (threshold %ss, checked_by=%s) ==\n' "$STALE_S" "$by"
  # §6.2 — THE WATCHDOG IS ITSELF WATCHED. The component checking the orchestrator must not be the
  # orchestrator: a party that can declare itself healthy will. The chain terminates at `verifier`,
  # which has no stake in the orchestrator's liveness.
  if [ "$by" = "session-orchestrator" ]; then
    echo "  [FAIL] session-orchestrator may not run its own stall check — the watchdog must be watched by another party"
    exit 1
  fi
  nowe=$(date -u +%s)
  # STORE 2, independent of any agent's self-report: real filesystem activity. Newest mtime across
  # the working tree and the audit trails.
  # THE TWO STORES MUST BE INDEPENDENT, and the first version of this was not: the activity scan
  # included logs/, which is where heartbeats are WRITTEN. Recording a heartbeat therefore made the
  # tree look active, so "stale heartbeat AND no activity" could never both hold and STALL was
  # unreachable — a detector that cannot fire, which is this project's most-recorded defect wearing
  # a new hat. logs/ and .claude/state/ are excluded so store 2 observes real work only.
  act=$(find . -path ./.git -prune -o -path ./logs -prune -o -path ./.claude/state -prune \
             -o -type f -newermt "-${STALE_S} seconds" -print 2>/dev/null | head -1)
  stalled=""; diverged=""
  for a in $AGENTS; do
    last=$(jq -r --arg a "$a" 'select(.agent==$a and .event=="heartbeat") | .ts' "$HB" 2>/dev/null | tail -1)
    if [ -z "$last" ]; then
      # Absence is not a stall. An agent that never ran has nothing to be stuck at, and treating
      # silence as failure is how a monitor cries wolf on its first day.
      printf '  [none]  %-22s no heartbeat ever recorded — not a stall, nothing has run\n' "$a"
      continue
    fi
    age=$(( nowe - $(epoch_of "$last") ))
    st=$(jq -r --arg a "$a" 'select(.agent==$a and .event=="heartbeat") | .state' "$HB" 2>/dev/null | tail -1)
    if [ "$age" -le "$STALE_S" ]; then
      printf '  [live]  %-22s %ss ago, state=%s\n' "$a" "$age" "$st"
    elif [ -n "$act" ]; then
      # GASTOWN'S HARD-WON RULE, inherited without paying for it: NEVER declare an agent stuck from
      # a single store. A stale heartbeat beside live filesystem activity is heartbeat-write
      # DIVERGENCE, not a stuck agent. Their false escalation (hq-qxl9) came from exactly this.
      printf '  [diverged] %-19s heartbeat %ss stale BUT the tree changed within %ss — write divergence, not a stall\n' "$a" "$age" "$STALE_S"
      diverged="$diverged $a"
    else
      printf '  [STALL] %-22s heartbeat %ss stale AND no filesystem activity in %ss — two stores agree\n' "$a" "$age" "$STALE_S"
      stalled="$stalled $a"
    fi
  done
  mkdir -p logs
  jq -cn --arg ts "$(now)" --arg by "$by" --arg s "$stalled" --arg d "$diverged" --arg p "$(phase_now)" \
     '{ts:$ts,event:"watchdog",checked_by:$by,stalled:$s,diverged:$d,phase:$p}' >> "$HB"
  if [ -n "$stalled" ]; then echo "  == STALLED:$stalled =="; exit 1; fi
  [ -n "$diverged" ] && echo "  == divergence, not escalated:$diverged =="
  echo "  == no stall =="
  ;;

orient)
  # GUPP is not adopted, but its ENABLER is: an agent discovers its own state rather than being
  # briefed. A briefing is a copy, and a copy is what drifts.
  echo "== orientation =="
  printf '  phase          %s\n' "$(phase_now)"
  pend=$(grep -oE 'awaiting `APPROVE (GATE-L[0-9]+)`' GATES.md 2>/dev/null | grep -oE 'GATE-L[0-9]+' | head -1)
  printf '  pending gate   %s\n' "${pend:-none}"
  printf '  next action    %s\n' "$(grep -E '^- \*\*Next action:' PROGRESS.md 2>/dev/null | tail -1 | sed 's/^- \*\*Next action:\*\*[[:space:]]*//')"
  printf '  head           %s (%s dirty)\n' "$(git rev-parse --short HEAD 2>/dev/null || echo none)" "$(git status --porcelain 2>/dev/null | wc -l)"
  printf '  release law    no output is acted on until a party that did not produce it releases it\n'
  echo "  last heartbeat per agent:"
  for a in $AGENTS; do
    l=$(jq -r --arg a "$a" 'select(.agent==$a and .event=="heartbeat") | "\(.ts) \(.state)"' "$HB" 2>/dev/null | tail -1)
    printf '    %-22s %s\n' "$a" "${l:-—}"
  done
  ;;

seance)
  q="${2:?query required}"
  # §6.3 — a successor queries its predecessor's EVENTS rather than inheriting a distillation.
  # Distillation loses detail by design; that is what makes it useful and also what makes this
  # necessary. Additive to the summary, never a replacement for it.
  printf '== seance: raw events matching "%s" ==\n' "$q"
  hits=0
  for f in logs/heartbeats.jsonl logs/release-audit.jsonl logs/deny-audit.jsonl; do
    [ -f "$f" ] || continue
    m=$(grep -i -- "$q" "$f" 2>/dev/null | tail -20)
    if [ -n "$m" ]; then printf '\n--- %s ---\n' "$f"; printf '%s\n' "$m"; hits=$((hits+1)); fi
  done
  for f in Plan.md PROGRESS.md GATES.md; do
    m=$(grep -in -- "$q" "$f" 2>/dev/null | tail -10)
    if [ -n "$m" ]; then printf '\n--- %s ---\n' "$f"; printf '%s\n' "$m"; hits=$((hits+1)); fi
  done
  if [ "$hits" = 0 ]; then
    # Reported, never silent. "No events" and "the log is missing" are different answers and a
    # successor session must be able to tell them apart.
    printf '\n  no events matched. Logs present: %s\n' "$(ls logs/*.jsonl 2>/dev/null | tr '\n' ' ' || echo none)"
  fi
  ;;

*) echo "usage: continuity.sh [heartbeat <agent> <state> [note]|stalls [--as <agent>]|orient|seance <query>]"; exit 64 ;;
esac
