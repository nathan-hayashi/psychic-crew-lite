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
  # ADDED is the one relation with no parent side: a Lite-first artifact. Checked first, because
  # the parent-path rule below would otherwise fail every one of them on a path that is meant to
  # be absent.
  if [ "$rel" = "ADDED" ]; then
    if [ "$ppath" != "—" ] && [ -n "$ppath" ]; then
      fail "ADDED row names a parent path ($ppath); use MIRRORED or ADAPTED"
    elif [ -e "$lpath" ]; then
      pass "ADDED, Lite-first and declared — $lpath"
    else
      fail "ADDED: lite path missing — $lpath"
    fi
    continue
  fi
  # Every parent path must still exist for every other relation. A DROPPED row whose parent
  # vanished is a decision about something that no longer exists.
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

# MAP COMPLETENESS, in the Lite direction. Every row above proves a DECLARED artifact is in the
# state its relation claims — and nothing proved the converse: that a Lite file is declared at all.
# The ADDED relation made declaring a Lite-first artifact possible at L1; it did not make it
# required, so an undeclared file was still invisible to the map whose whole purpose is that nothing
# is undeclared. That is C-26's shape exactly: the check looked complete and never covered the
# directory that mattered.
#
# Scoped to the machinery directories. Ledgers, README and docs are prose that changes every session
# and declaring each one would be noise, not coverage.
declared=$(printf '%s\n' "$ROWS" | cut -f3 | grep -v '^—$' | sort -u)
ontree=$(git ls-files 'hooks/*' 'scripts/*' '.claude/*' 2>/dev/null | sort -u)
ndec=$(printf '%s\n' "$declared" | grep -c . || true)
ntree=$(printf '%s\n' "$ontree" | grep -c . || true)
if [ "${ndec:-0}" -lt 5 ] || [ "${ntree:-0}" -lt 5 ]; then
  fail "map-completeness extraction is vacuous (declared:$ndec tree:$ntree) — the comparison below would prove nothing"
else
  undeclared=$(comm -13 <(printf '%s\n' "$declared") <(printf '%s\n' "$ontree") | tr '\n' ' ')
  [ -z "$undeclared" ] \
    && pass "every tracked file under hooks/ scripts/ .claude/ is declared in the map ($ntree files)" \
    || fail "UNDECLARED Lite file(s) — the map does not mention:[$undeclared] (use ADDED, ADAPTED or MIRRORED)"
fi

# Vocabulary parity, a targeted byte-check inside an ADAPTED file. security.md was MIRRORED until
# L1 and was reclassified because byte-identity shipped references to an arbiter this build does
# not have. What mattered about MIRRORED was not the whole file — it was that two builds exchanging
# findings must agree on what `crit` means. So the severity ROWS are pinned even though the file is
# not, and the parity is asserted rather than trusted.
sev_l=$(grep -E '^\| `(crit|high|med|low)` \|' .claude/rules/security.md 2>/dev/null | sort)
sev_p=$(grep -E '^\| `(crit|high|med|low)` \|' "$PARENT/.claude/rules/security.md" 2>/dev/null | sort)
# Vacuity guard: two empty extractions are identical, and that would silently switch this off.
if [ "$(printf '%s\n' "$sev_l" | grep -c .)" -ne 4 ] || [ "$(printf '%s\n' "$sev_p" | grep -c .)" -ne 4 ]; then
  fail "severity table did not parse on one side (lite:$(printf '%s\n' "$sev_l" | grep -c .) parent:$(printf '%s\n' "$sev_p" | grep -c .)) — parity below would be vacuous"
elif [ "$sev_l" = "$sev_p" ]; then
  pass "severity vocabulary byte-identical to the parent (4 rows) despite security.md being ADAPTED"
else
  fail "SEVERITY VOCABULARY DIVERGED — the two builds no longer mean the same thing by crit/high/med/low"
fi

printf '\n== check-sync: %s PASS / %s FAIL / %s REVIEW ==\n' "$P" "$F" "$W"
[ "$F" = 0 ] || exit 1
