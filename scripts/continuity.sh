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
HB="logs/heartbeats.jsonl"        # RUNTIME: high-frequency, gitignored, one machine
SH="docs/session-history.jsonl"   # DURABLE: tracked, append-only, survives a clone
#
# THE SPLIT IS DELIBERATE. The raw heartbeat log is NOT tracked, for two reasons. It is chatter —
# tracking it means a diff on every heartbeat and a conflict on every parallel session. And it would
# put runtime state and history in one file, which is the C-13/C-14 lesson: once two categories
# share an artifact, no reader can tell which is which.
#
# What is durable is a RECORDED CHECKPOINT: one line per `record`, carrying the commit, so a
# successor on a fresh clone can reconstruct what happened and bisect it. Same shape as
# docs/verification-history.jsonl, which already proved it.
#
# STATED LIMIT: the durable record holds checkpoints, not every heartbeat. A successor on another
# machine sees the checkpoints and NOT the intervening chatter, and `seance` labels every hit with
# which store it came from so that difference is visible rather than silently smaller.
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

record)
  by="${3:-verifier}"; [ "${2:-}" = "--as" ] || by="verifier"
  # REFUSES OUTSIDE A WORK TREE. Fixtures and stress harnesses run under mktemp roots; a durable
  # history that accepts fixture data is a history nobody can trust, which is exactly what C-14
  # recorded when synthetic records entered a live trail.
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "  [FAIL] refusing to record: not a git work tree, so this is a fixture root, not a session"
    exit 1
  fi
  mkdir -p docs
  states=$(for a in $AGENTS; do
             s=$(jq -r --arg a "$a" 'select(.agent==$a and .event=="heartbeat") | .state' "$HB" 2>/dev/null | tail -1)
             printf '%s=%s;' "$a" "${s:-none}"
           done)
  wd=$(jq -r 'select(.event=="watchdog") | "\(.checked_by):stalled[\(.stalled)]diverged[\(.diverged)]"' "$HB" 2>/dev/null | tail -1)
  before=$(grep -c . "$SH" 2>/dev/null) || true; case "$before" in ''|*[!0-9]*) before=0 ;; esac
  # `grep -c` prints 0 AND exits 1 on no match, so `grep -c . || echo 0` yields the two-line string
  # "0\n0", which is not valid JSON and breaks --argjson. It misbehaves only on a CLEAN tree.
  # This is the FIFTH appearance of that idiom in this build and the second time it broke a history
  # write — I reproduced the L2 defect three lines below the comment that cites it. The
  # confirm-it-landed guard is what caught it: the write failed loudly instead of reporting success
  # over an empty file, which is the entire argument for that guard existing.
  ndirty=$(git status --porcelain 2>/dev/null | grep -c . 2>/dev/null) || true
  case "$ndirty" in ''|*[!0-9]*) ndirty=0 ;; esac
  jq -cn --arg ts "$(now)" --arg c "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
         --argjson dirty "$ndirty" \
         --arg p "$(phase_now)" --arg by "$by" --arg st "$states" --arg wd "${wd:-none}" \
         --arg na "$(grep -E '^- \*\*Next action:' PROGRESS.md 2>/dev/null | tail -1 | sed 's/^- \*\*Next action:\*\*[[:space:]]*//' | cut -c1-200)" \
     '{ts:$ts,event:"checkpoint",commit:$c,dirty:$dirty,phase:$p,recorded_by:$by,
       agent_states:$st,watchdog:$wd,next_action:$na}' >> "$SH"
  # CONFIRM IT LANDED. The L2 history write once reported success while appending nothing, because a
  # broken --argjson made jq emit nothing and the step printed "recorded" over an empty file.
  after=$(grep -c . "$SH" 2>/dev/null) || true; case "$after" in ''|*[!0-9]*) after=0 ;; esac
  if [ "$after" -le "$before" ]; then
    echo "  [FAIL] durable record did NOT land — $SH still has $after entries"; exit 1
  elif ! tail -1 "$SH" | jq -e '.commit and .phase and .event=="checkpoint"' >/dev/null 2>&1; then
    echo "  [FAIL] durable line landed but does not parse or lacks required fields"; exit 1
  fi
  printf '  [ok] checkpoint recorded to %s (%s entries, was %s)\n' "$SH" "$after" "$before"
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
    printf '  durable       %s checkpoint(s) in %s (survives a clone)\n' \
      "$( [ -f "$SH" ] && grep -c . "$SH" 2>/dev/null || echo 0 )" "$SH"
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
    hits=0; dhits=0
    # DURABLE FIRST, and labelled. A successor on a fresh clone has only this half; one on the
    # origin machine has both. Labelling every hit with its store makes that difference visible —
    # an unlabelled result set would look complete on a machine where it is not.
    if [ -f "$SH" ]; then
      m=$(grep -i -- "$q" "$SH" 2>/dev/null | tail -20)
      if [ -n "$m" ]; then printf '\n--- %s  [durable: survives a clone] ---\n' "$SH"; printf '%s\n' "$m"; hits=$((hits+1)); dhits=1; fi
    fi
    for f in logs/heartbeats.jsonl logs/release-audit.jsonl logs/deny-audit.jsonl; do
      [ -f "$f" ] || continue
      m=$(grep -i -- "$q" "$f" 2>/dev/null | tail -20)
      if [ -n "$m" ]; then printf '\n--- %s  [runtime: this machine only] ---\n' "$f"; printf '%s\n' "$m"; hits=$((hits+1)); fi
    done
  for f in Plan.md PROGRESS.md GATES.md; do
    m=$(grep -in -- "$q" "$f" 2>/dev/null | tail -10)
    if [ -n "$m" ]; then printf '\n--- %s ---\n' "$f"; printf '%s\n' "$m"; hits=$((hits+1)); fi
  done
  if [ "$hits" = 0 ]; then
    # Reported, never silent. "No events" and "the log is missing" are different answers and a
    # successor session must be able to tell them apart.
      printf '\n  no events matched. Durable: %s checkpoint(s). Runtime logs: %s\n' \
        "$( [ -f "$SH" ] && grep -c . "$SH" 2>/dev/null || echo 0 )" \
        "$(ls logs/*.jsonl 2>/dev/null | tr '\n' ' ' || echo none)"
    elif [ "$dhits" = 0 ]; then
      # Said out loud rather than left to inference: every hit came from a store that does not
      # travel, so a successor on another machine would have found nothing at all.
      printf '\n  NOTE: no DURABLE hit — this answer does not travel to a fresh clone.\n'
  fi
  ;;

*) echo "usage: continuity.sh [heartbeat <agent> <state> [note]|stalls [--as <agent>]|record [--as <agent>]|orient|seance <query>]"; exit 64 ;;
esac
