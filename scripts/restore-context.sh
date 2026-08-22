#!/usr/bin/env bash
# restore-context.sh [latest|<n>|<file>] — forward-resume. Prints a snapshot and the reload
# instruction. READ-ONLY: a restore path that can write is a restore path that can corrupt.
set -uo pipefail
cd "$(dirname "$0")/.."
CK=".claude/state/checkpoints"
A="${1:-latest}"
case "$A" in
  latest) F="$CK/latest.md" ;;
  ''|*[!0-9]*) F="$A" ;;
  *) F=$(ls -1t "$CK"/ckpt-*.md 2>/dev/null | sed -n "${A}p") ;;
esac
if [ -z "${F:-}" ] || [ ! -f "$F" ]; then
  echo "[FAIL] no snapshot for '$A'. Available:"; ls -1t "$CK" 2>/dev/null | sed 's/^/  /'; exit 1
fi
echo "===== $F ====="; cat "$F"
cat <<'MSG'

===== RELOAD INSTRUCTION (paste after any compaction, /clear, or new session) =====
Disk is canonical; the window you are reading is a cache. Before acting:
  1. ./scripts/continuity.sh orient      — phase, pending gate, declared next action
  2. PROGRESS.md tail + GATES.md         — the ledgers, which outrank any summary
  3. context/session-summary.md          — distilled state, labelled verified/proposed
  4. ./scripts/continuity.sh seance <q>  — query the predecessor's event log for what the
                                           summary dropped; distillation loses detail BY DESIGN
Then state the recorded next action and continue strictly forward: never regress, never re-run an
artifact that already exists.
MSG
