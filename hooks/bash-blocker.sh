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
  *"git clone"*)      deny "LC-5: cloning is prohibited - this build is from scratch" ;;
  *"npx "*)        deny "LC-5: npx fetches packages at run time - prohibited" ;;
  *"npm install -g"*)       deny "LC-5: global package install prohibited" ;;
  *"sudo "*)       deny "LC-5: elevated execution prohibited" ;;
  *"curl "*"|"*"sh"*|*"wget "*"|"*"sh"*) deny "LC-5: fetch-piped-to-shell prohibited" ;;
  *"terraform destroy"*|*"kubectl delete namespace"*) deny "destructive infrastructure command blocked" ;;
  *codex*|*chatgpt*) deny "LC-7: this build is Claude-only - no non-Claude model or CLI invocation" ;;
esac
exit 0
