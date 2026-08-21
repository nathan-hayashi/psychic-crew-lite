#!/usr/bin/env bash
# Stop[*] — rolling snapshot, plus the pending-gate toast.
#
# This file is why Lite gate rows live in this repo's ledger rather than the parent's. The parent's
# stop hook resolves a pending gate with a pattern matching its own F-series tokens, so an L-series
# row over there would be a gate awaiting a token that nothing announces. Registered at L0 as an L1
# input; this is it.
set -uo pipefail
. "$(dirname "$0")/_common.sh" 2>/dev/null || true
ST="$ROOT/.claude/state"; CK="$ST/checkpoints"
{
  mkdir -p "$CK" 2>/dev/null || true
  {
    printf '# latest (rolling, refreshed every turn) — %s (%s)\n\n## PROGRESS.md (tail 40)\n' "$(now)" "$PHASE"
    tail -40 "$ROOT/PROGRESS.md" 2>/dev/null
    printf '\n## GATES.md (tail)\n'; tail -4 "$ROOT/GATES.md" 2>/dev/null
    printf '\n## git\n'; (cd "$ROOT" && git status --short 2>/dev/null; echo "HEAD $(git rev-parse HEAD 2>/dev/null)")
    printf '\n## declared next_action\n'; grep -E '^- \*\*Next action:' "$ROOT/PROGRESS.md" 2>/dev/null | tail -1
  } > "$CK/latest.md" 2>/dev/null || true
} 2>/dev/null

# GATES.md is the authority, not PROGRESS.md prose: the ledger is what a token is actually recorded
# against, so a stale checkpoint sentence cannot manufacture a GATE READY alert.
MSG="turn complete"
PEND=$(grep -oE 'awaiting `APPROVE (GATE-L[0-9]+)`' "$ROOT/GATES.md" 2>/dev/null | grep -oE 'GATE-L[0-9]+' | head -1 || true)
[ -n "${PEND:-}" ] && MSG="GATE READY — $PEND awaiting your token"
command -v wsl-notify-send.exe >/dev/null 2>&1 && wsl-notify-send.exe "psychic-crew-lite" "$MSG" >/dev/null 2>&1 || true
exit 0
