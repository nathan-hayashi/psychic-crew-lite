#!/usr/bin/env bash
# SessionStart — re-grounding. Disk is canonical, the context window is a cache.
set -uo pipefail
. "$(dirname "$0")/_common.sh" 2>/dev/null || true
CTX=$( {
  printf 'psychic-crew-lite re-grounding. Disk is canonical; this window is a cache. Phase: %s\n' "$PHASE"
  printf 'Recorded next action: %s\n' "$(grep -E '^- \*\*Next action:' "$ROOT/PROGRESS.md" 2>/dev/null | tail -1)"
  printf 'Read before acting: PROGRESS.md tail, GATES.md, Plan.md tail.\n'
  printf 'No arbiter here: no output is acted on until a party that did not produce it has released it.\n'
  [ -f "$ROOT/.claude/state/checkpoints/latest.md" ] && printf 'A rolling snapshot exists at .claude/state/checkpoints/latest.md\n'
  printf 'A phase BEGINS on plain instruction and ENDS at its exact token APPROVE GATE-Ln.\n'
} 2>/dev/null )
jq -cn --arg c "$CTX" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
