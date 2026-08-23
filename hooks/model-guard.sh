#!/usr/bin/env bash
# PreToolUse[Write|Edit] — LC-2: block any write that would make a forbidden model reachable.
#
# ADAPTED from the parent, and the adaptation is the whole point. The parent scans assignment
# POSITIONS for a forbidden substring, which is correct when agents name models directly. Here they
# name a CLASS, so resolution is class -> alias -> id and a forbidden model can be reachable with no
# forbidden substring anywhere near an agent. model-policy.md states the rule this enforces: the
# scan must run against the RESOLVED value.
#
# Assignment positions only, never a bare substring scan. A substring scan would block this repo's
# own model-policy.md, and would make this very file unwriteable since it must contain what it
# matches.
set -uo pipefail
. "$(dirname "$0")/_common.sh"
INPUT=$(cat 2>/dev/null || true)
F=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
C=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)
[ -n "$F" ] || exit 0
case "$F" in
  */.claude/*|*/models.config.json|*models.config.json) ;;
  *) exit 0 ;;
esac
BAD=$(jq -r '.forbidden_substrings[]' "$ROOT/models.config.json" 2>/dev/null || echo fable)

# Path A — the config itself, checked by RESOLUTION rather than by pattern. If the proposed content
# is valid JSON, every agent is resolved through it exactly as apply-models.sh would, so a class
# quietly repointed at a forbidden model is caught even though the agent file never changes and the
# word never appears next to an agent.
case "$F" in
  *models.config.json)
    if printf '%s' "$C" | jq -e . >/dev/null 2>&1; then
      for b in $BAD; do
        hit=$(printf '%s' "$C" | jq -r --arg b "$b" '. as $r
          | [ (($r.agents // {}) | to_entries[] | .value.class as $c
                | (($r.classes // {})[$c]) as $al
                | ((($r.aliases // {})[$al]) // ""), ((($r.pinned // {})[$al]) // "")),
              (($r.aliases // {}) | to_entries[] | .value),
              (($r.pinned  // {}) | to_entries[] | .value),
              (($r.session // {}).model // "") ]
          | map(select(type == "string" and (ascii_downcase | contains($b)))) | .[0] // ""' 2>/dev/null)
        [ -z "$hit" ] || deny "LC-2: this config makes a forbidden ($b) model reachable - resolved value '$hit'"
      done
    fi ;;
esac

# Path B — any other config-surface file: assignment positions for model:, class: and effort-free
# aliases. A class naming a forbidden model directly is caught here even outside the config.
for b in $BAD; do
  if grep -qiE "^[[:space:]]*[\"-]?[[:space:]]*(model|class)\"?[[:space:]]*:[[:space:]]*\"?[^\",}]*${b}" <<<"$C"; then
    deny "LC-2: write assigns a forbidden ($b) model or class into the config surface"
  fi
done
exit 0
