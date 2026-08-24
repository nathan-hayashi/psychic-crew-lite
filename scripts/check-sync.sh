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

# Anchored on the VERSIONED header, not the prefix. The same loose form in check-witness.sh matched
# that document's own H1, so extraction read prose as rows and --refresh destroyed the file. This
# one happens to be safe today only because no other line starts with the prefix; that is luck, and
# the class has already proven itself destructive once here.
ROWS=$(awk '/^# SYNC-MAP v[0-9]+$/{f=1;next} f&&/^```/{exit} f&&NF' "$MAP" 2>/dev/null)
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
  # PACK (R-SP-1) — Lite-only, parent-side refusal, proposal-only under A4a. Checked before the
  # parent-path rule below, which would otherwise fail every pack on a path meant to be absent.
  if [ "$rel" = "PACK" ]; then
    if [ "$ppath" != "—" ] && [ -n "$ppath" ]; then
      fail "PACK row names a parent path ($ppath); a pack is Lite-only by definition"
    elif [ ! -e "$lpath" ]; then
      fail "PACK: declared pack is not on disk — $lpath"
    elif ! grep -qF -- "$lpath" <<<"$(awk '/^## Why each PACK row/,/^## Why each DROPPED/' "$MAP")"; then
      # The ruling requires a WHY on the parent side. A declared pack with no recorded reason is a
      # row that asserts a refusal nobody wrote down.
      fail "PACK: $lpath is declared but no 'why' is recorded for the parent-side refusal"
    else
      pass "PACK declared with a parent-side why — $lpath"
    fi
    continue
  fi
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
  # A PACK is declared at DIRECTORY granularity — that is what the R-SP-1 guard enumerates, and it
  # is the right unit: declaring every file inside a pack would turn §7.1 into a manifest of pack
  # contents, and would mean every edit inside a pack needs a map edit. That friction is what makes
  # people route around a map, which is worse than the coarser grain. So a tracked file living under
  # a DECLARED pack path is covered by its pack's row; a file under an UNDECLARED pack is still
  # caught, by the R-SP-1 guard above, naming the pack rather than each file inside it.
  packdirs=$(printf '%s\n' "$ROWS" | awk -F'\t' '$1=="PACK"{print $3}')
  ontree_nonpack=$(printf '%s\n' "$ontree" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      covered=0
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        case "$f" in "$d"/*) covered=1; break ;; esac
      done <<PACKEOF
$packdirs
PACKEOF
      [ "$covered" = 0 ] && printf '%s\n' "$f"
    done)
  undeclared=$(comm -13 <(printf '%s\n' "$declared") <(printf '%s\n' "$ontree_nonpack") | tr '\n' ' ')
  [ -z "$undeclared" ] \
    && pass "every tracked file under hooks/ scripts/ .claude/ is declared in the map ($ntree files)" \
    || fail "UNDECLARED Lite file(s) — the map does not mention:[$undeclared] (use ADDED, ADAPTED or MIRRORED)"
fi

# R-SP-1 CLASS GUARD — the direction that matters. Every row above proves a DECLARED pack is in the
# state its relation claims; this proves the converse, that a pack ON DISK is declared at all. That
# converse is the whole ruling: skill-packs open UNDER §7.1, so an undeclared pack is a failure
# rather than a thing someone should have remembered to add.
#
# Same shape as the map-completeness guard, and the same reason: `ADDED` made declaring a Lite-first
# artifact possible at L1 and did not make it required, and the gap sat there until it was closed.
PACKROOT=".claude/skills/packs"
packs_disk=$(find "$PACKROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
packs_decl=$(printf '%s\n' "$ROWS" | awk -F'\t' '$1=="PACK"{print $3}' | sort)
np_disk=$(grep -c . <<<"$packs_disk"); np_decl=$(grep -c . <<<"$packs_decl")
case "$np_disk" in ''|*[!0-9]*) np_disk=0 ;; esac
case "$np_decl" in ''|*[!0-9]*) np_decl=0 ;; esac
if [ ! -d "$PACKROOT" ] || [ "$np_disk" = 0 ]; then
  # ANNOUNCED, never a silent pass. A class guard with nothing to guard proves nothing, and saying
  # so is what keeps it from quietly becoming decoration before the first pack ever lands.
  pass "R-SP-1 pack guard armed; no pack on disk yet under $PACKROOT/ — nothing to correlate (declared: $np_decl)"
else
  undeclared=$(comm -13 <(printf '%s\n' "$packs_decl") <(printf '%s\n' "$packs_disk") | tr '\n' ' ')
  [ -z "$undeclared" ] \
    && pass "R-SP-1 every pack on disk is declared under §7.1 ($np_disk pack(s))" \
    || fail "R-SP-1 UNDECLARED pack(s) on disk — the map does not mention:[$undeclared] (add a PACK row and its why)"
fi

# R-PD-1 PACK CAP — packs #2 and beyond are deferred behind the security phase. Pack #1 was gated
# before a threat model existed for the intake path it opened; the ruling stops that ordering
# becoming the precedent that scales. The cap lifts MECHANICALLY, on an APPROVED row, never on
# anyone's recollection of what was agreed.
PD_LEDGER="GATES.md"
# The token INCLUDES its verb — the ledger records `APPROVE LITE-SECURITY-1`, not the bare gate
# name. Keying on the bare name matched nothing and the cap stayed shut while reporting normally,
# which is the fail-safe direction and still wrong: a guard that can never lift is not a guard.
PD_NEEDLE="**APPROVED** \`APPROVE LITE-SECURITY-1\`"
if [ -f "$PD_LEDGER" ]; then
  pd_rows=$(grep -cF -- "$PD_NEEDLE" "$PD_LEDGER" || true)
else
  # Fail CLOSED. A missing ledger is not an approval, and between two readings the strict one is the
  # only safe default — the permissive one would lift the cap by deleting a file.
  pd_rows=0
fi
case "$pd_rows" in ''|*[!0-9]*) pd_rows=0 ;; esac
if [ "$pd_rows" -gt 0 ]; then
  pass "R-PD-1 cap LIFTED — LITE-SECURITY-1 approved in $PD_LEDGER; further packs permitted ($np_disk on disk)"
elif [ "$np_disk" -le 1 ]; then
  pass "R-PD-1 pack cap armed and observed — $np_disk pack(s) on disk, security phase still open"
else
  pd_extra=$(printf '%s\n' "$packs_disk" | tail -n +2 | tr '\n' ' ')
  fail "R-PD-1 VIOLATED — $np_disk packs on disk with the security phase open; defer:[$pd_extra] until LITE-SECURITY-1 is approved"
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
