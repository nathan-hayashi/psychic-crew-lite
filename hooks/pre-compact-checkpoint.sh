#!/usr/bin/env bash
# PreCompact[auto|manual] — the emergency checkpoint. Deferred from L1 to here and recorded as a
# deferral rather than a rejection; this is it.
#
# Fires mid-flight. MUST never block or fail compaction: always exit 0, no prompts, bounded work.
set -uo pipefail
. "$(dirname "$0")/_common.sh" 2>/dev/null || true
{
  TS=$(now)
  STAMP=$(date -u +%Y%m%dT%H%M%SZ)   # colons are hostile in filenames
  ST="$ROOT/.claude/state"; CK="$ST/checkpoints"
  mkdir -p "$CK" 2>/dev/null || true

  # Capture the last REAL next action BEFORE appending. The parent's version once hardcoded a
  # pointer here ("see the tail of Plan.md"), which then BECAME the newest Next action line — so the
  # cold reader recovered the pointer instead of the instruction it displaced. The parachute was
  # degrading the one field it exists to protect. Carry it forward verbatim.
  PRIOR=$(grep -E '^- \*\*Next action:' "$ROOT/PROGRESS.md" 2>/dev/null | tail -1 \
          | sed 's/^- \*\*Next action:\*\*[[:space:]]*//')
  {
    printf '\n## [%s|%s] EMERGENCY CHECKPOINT (PreCompact)\n' "$PHASE" "$TS"
    printf -- '- **In-flight:** %s file(s) uncommitted\n' "$(cd "$ROOT" && git status --porcelain 2>/dev/null | wc -l)"
    printf -- '- **HEAD:** %s\n' "$(cd "$ROOT" && git rev-parse --short HEAD 2>/dev/null || echo none)"
    printf -- '- **Recovery:** ./scripts/restore-context.sh, then ./scripts/continuity.sh orient\n'
    printf -- '- **Next action:** %s\n' "${PRIOR:-run ./scripts/continuity.sh orient and read the newest snapshot}"
  } >> "$ROOT/PROGRESS.md" 2>/dev/null || true

  : > "$ST/compact-pending" 2>/dev/null || true

  SNAP="$CK/ckpt-$STAMP-${PHASE}.md"
  {
    printf '# checkpoint %s (%s)\n\n## PROGRESS.md (tail 40)\n' "$STAMP" "$PHASE"
    tail -40 "$ROOT/PROGRESS.md" 2>/dev/null
    printf '\n## GATES.md (tail)\n'; tail -4 "$ROOT/GATES.md" 2>/dev/null
    printf '\n## git\n'; (cd "$ROOT" && git status --short 2>/dev/null; echo "HEAD $(git rev-parse HEAD 2>/dev/null)")
    printf '\n## last heartbeats\n'; tail -8 "$ROOT/logs/heartbeats.jsonl" 2>/dev/null
    printf '\n## declared next_action\n'; grep -E '^- \*\*Next action:' "$ROOT/PROGRESS.md" 2>/dev/null | tail -1
  } > "$SNAP" 2>/dev/null || true

  # Retention: keep the newest 10.
  ls -1t "$CK"/ckpt-*.md 2>/dev/null | tail -n +11 | while read -r old; do rm -f "$old" 2>/dev/null || true; done
} 2>/dev/null
exit 0
