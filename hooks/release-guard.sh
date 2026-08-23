#!/usr/bin/env bash
# PreToolUse[Write|Edit|Bash] — enforce the ONE law this roster replaces the arbiter with:
# no party releases its own output. released_by MUST differ from from_agent.
#
# The parent enforced its equivalent by audit only, and said so: a bypass was caught, never
# prevented. Here the check is cheap and the artifact is a JSON line, so the write itself is
# refused wherever the content is visible to the hook.
#
# WHAT THIS DOES NOT COVER, stated rather than implied: a line assembled from shell variables, or
# appended by any path whose content the hook cannot read, is invisible here. Those are caught by
# scripts/validate-lite.sh, which scans the whole trail at the gate. Hook plus scan, and neither is
# claimed to be the other.
set -uo pipefail
. "$(dirname "$0")/_common.sh"
INPUT=$(cat 2>/dev/null || true)
F=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
C=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Only ever inspect payloads bound for the release trail.
BODY=""
case "$F" in *release-audit.jsonl) BODY="$C" ;; esac
case "$CMD" in *release-audit.jsonl*) BODY="$BODY
$CMD" ;; esac
[ -n "$BODY" ] || exit 0

# Every complete JSON object in the payload is checked. grep -o keeps it to objects, so surrounding
# shell syntax in a Bash command does not have to parse.
self_hits=$(printf '%s' "$BODY" | grep -oE '\{[^{}]*"released_by"[^{}]*\}' 2>/dev/null | while IFS= read -r obj; do
  fa=$(printf '%s' "$obj" | jq -r '.from_agent // empty' 2>/dev/null || true)
  rb=$(printf '%s' "$obj" | jq -r '.released_by // empty' 2>/dev/null || true)
  [ -n "$fa" ] && [ -n "$rb" ] && [ "$fa" = "$rb" ] && echo SELF && break
done)
grep -q SELF <<<"$self_hits" && deny "release protocol: released_by equals from_agent - a party may not release its own output"

# A release line with no task_id cannot be correlated to the dispatch it covers, and coverage
# correlated by count rather than identity is satisfiable by the audited party.
noid_hits=$(printf '%s' "$BODY" | grep -oE '\{[^{}]*"released_by"[^{}]*\}' 2>/dev/null | while IFS= read -r obj; do
  ti=$(printf '%s' "$obj" | jq -r '.task_id // empty' 2>/dev/null || true)
  [ -z "$ti" ] && echo NOID && break
done)
grep -q NOID <<<"$noid_hits" && deny "release protocol: release line carries no task_id - coverage would be uncorrelatable"
exit 0
