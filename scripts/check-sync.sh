#!/usr/bin/env bash
# check-sync.sh — enforce docs/SYNC-CORRELATION.md (plan §7.1).
#
# The map is the requirement; this is what stops it being documentation that rots. The parent build
# recorded exactly that failure class: a map and a tree drifted apart in BOTH directions and the
# only check pointed at them read a hardcoded list instead of the map (CR-024).
#
# Parent located via $PSYCHIC_CREW_PARENT, defaulting under $HOME. No absolute machine path appears
# here — two red gates in the parent came from writing one into a tracked file.
set -uo pipefail
cd "$(dirname "$0")/.."
PARENT="${PSYCHIC_CREW_PARENT:-$HOME/projects/psychic-crew}"
MAP="docs/SYNC-CORRELATION.md"
P=0; F=0; W=0
pass () { P=$((P+1)); printf '  [PASS] %s\n' "$1"; }
fail () { F=$((F+1)); printf '  [FAIL] %s\n' "$1"; }
warn () { W=$((W+1)); printf '  [REVIEW] %s\n' "$1"; }

[ -d "$PARENT" ] || { echo "  [SKIP] parent repo not found at \$PSYCHIC_CREW_PARENT"; echo "== check-sync: skipped =="; exit 0; }

ROWS=$(awk '/^# SYNC-MAP/{f=1;next} f&&/^```/{exit} f&&NF' "$MAP" 2>/dev/null)
# Vacuity guard first. A map that parses to nothing makes every comparison below trivially clean,
# which is how a parser change silently switches this check off.
[ "$(printf '%s\n' "$ROWS" | grep -c .)" -ge 5 ] \
  && pass "sync map parses to $(printf '%s\n' "$ROWS" | grep -c .) rows" \
  || fail "sync map did not parse — every comparison below would be vacuous"

while IFS="$(printf '\t')" read -r rel ppath lpath; do
  [ -n "${rel:-}" ] || continue
  # Every parent path must still exist, whatever the relation. A DROPPED row whose parent vanished
  # is a decision about something that no longer exists.
  if [ ! -e "$PARENT/$ppath" ]; then
    fail "$rel: parent path gone — $ppath"
    continue
  fi
  case "$rel" in
    MIRRORED)
      if [ ! -e "$lpath" ]; then
        fail "MIRRORED: lite path missing — $lpath"
      elif [ "$(sha256sum "$PARENT/$ppath" | cut -d' ' -f1)" = "$(sha256sum "$lpath" | cut -d' ' -f1)" ]; then
        pass "MIRRORED byte-identical — $lpath"
      else
        fail "MIRRORED DIVERGED — $lpath differs from parent $ppath"
      fi ;;
    ADAPTED)
      if [ -e "$lpath" ]; then
        pass "ADAPTED present, divergence expected — $lpath"
      else
        fail "ADAPTED: lite path missing — $lpath"
      fi ;;
    DROPPED)
      if [ "$lpath" = "—" ] || [ -z "$lpath" ]; then
        pass "DROPPED, absence is recorded — $ppath"
      else
        fail "DROPPED row names a lite path ($lpath); use ADAPTED or MIRRORED"
      fi ;;
    *) fail "unknown relation '$rel' for $ppath" ;;
  esac
done <<EOF
$ROWS
EOF

printf '\n== check-sync: %s PASS / %s FAIL / %s REVIEW ==\n' "$P" "$F" "$W"
[ "$F" = 0 ] || exit 1
