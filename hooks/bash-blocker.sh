#!/usr/bin/env bash
# PreToolUse[Bash] — deny destructive commands and the LC-5 / LC-7 prohibited set.
#
# Whole-string case patterns, deliberately: a token-aware parser would be a second implementation
# of shell quoting and would disagree with the real shell somewhere. Matching the raw string is
# blunt and occasionally over-broad, and over-broad is the correct direction for a guard.
#
# NOTE FOR ANYONE EDITING THIS FILE: the patterns below are the literal strings this guard denies,
# so any command that QUOTES this region is itself denied. The parent build burned two red gates on
# exactly that, and writing this very file was denied twice for the same reason. Assemble the
# tokens from fragments when writing or quoting them.
set -uo pipefail
. "$(dirname "$0")/_common.sh"
INPUT=$(cat 2>/dev/null || true)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -n "$CMD" ] || exit 0
case "$CMD" in
  *"rm -rf /"*|*"rm -rf ~"*|*'rm -rf $HOME'*|*"dd if="*|*":(){"*)
      deny "destructive command blocked" ;;
  *"sudo "*)       deny "LC-5: elevated execution prohibited" ;;
  *"terraform destroy"*|*"kubectl delete namespace"*) deny "destructive infrastructure command blocked" ;;
esac

# R-PR-1 (HARNESS-CONV-1): everything ABOVE this line is UNIVERSAL SAFETY — it ran already, before
# any profile logic, so no marker, no resolver failure and no session-root confusion can make a
# destructive command reachable. Everything BELOW binds only a harness-build checkout.
#
# Two-root law: the profile is resolved from THIS SCRIPT'S OWN repo (a session rooted elsewhere
# must not disable these arms — CLAUDE_PROJECT_DIR is the SESSION root and is only ever the log
# destination). A missing resolver fails CLOSED to harness-build: enforcing build constraints in a
# repo that is not a harness is an inconvenience; not enforcing them in one is a breach.
_bb_self="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$(dirname "$0")/_profile.sh" ]; then
  . "$(dirname "$0")/_profile.sh"
  _bb_profile="$(profile_of "$_bb_self")"
else
  _bb_profile="harness-build"
fi
[ "$_bb_profile" = "harness-build" ] || exit 0

case "$CMD" in
  *"git clone"*)      deny "LC-5: cloning is prohibited - this build is from scratch" ;;
  *"npx "*)        deny "LC-5: npx fetches packages at run time - prohibited" ;;
  *"npm install -g"*)       deny "LC-5: global package install prohibited" ;;
  *"curl "*"|"*"sh"*|*"wget "*"|"*"sh"*) deny "LC-5: fetch-piped-to-shell prohibited" ;;
  *codex*|*chatgpt*) deny "LC-7: this build is Claude-only - no non-Claude model or CLI invocation" ;;
esac
exit 0
