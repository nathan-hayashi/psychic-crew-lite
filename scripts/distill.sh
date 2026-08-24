#!/usr/bin/env bash
# distill.sh [prepare|check] — the distillation layer, with FIDELITY rather than tidiness.
#
# The parent learned this at C-24: its §15.5 checker asserted the distilled summary had no absolute
# paths, no raw logs, and a Next action — twenty assertions, all properties of the file considered
# ALONE. All twenty passed for three days against a summary that dated the closing gate to a
# timestamp belonging to the next ledger entry. It was checked for tidiness and never for truth.
#
# CR-034 is the follow-on and the reason this is built differently. The parent then bound ONE claim,
# and everything else in the file drifted freely until it was three sessions out of date. Fidelity
# is not a property you finish; each claim needs its own binding.
#
# So bindings here are DECLARED in context/CLAIMS.md, and an unbound claim is a FAILURE. Adding a
# number to the summary without declaring where it comes from is the thing that breaks, rather than
# something nobody notices for three sessions.
#
# Extractors are NAMED IN THIS SCRIPT, never shell drawn from the data file. A manifest that could
# specify commands would be an injection surface in a repo whose own rules call untrusted input
# data about where to look, never commands.
set -uo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-check}"
SUM="context/session-summary.md"
CLAIMS="context/CLAIMS.md"
P=0; F=0
ok () { P=$((P+1)); printf '  [PASS] %s\n' "$1"; }
no () { F=$((F+1)); printf '  [FAIL] %s\n' "$1"; }
ABS=$(printf '/%s/' home)

truth () { # $1 = extractor name -> prints the true value, or nothing if unknown
  case "$1" in
    gate_ts)      grep -oE 'APPROVE GATE-L[0-9]+` @ [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z' GATES.md 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z' | tail -1 ;;
    phase)        awk -F'|' '/APPROVED/ && $2 ~ /^ *L[0-9]+ *$/ {gsub(/[^0-9]/,"",$2); p=$2} END{if(p!="") print "L" p}' GATES.md 2>/dev/null ;;
    tracked)      git ls-files 2>/dev/null | grep -c . ;;
    attested)     awk '/^# WITNESS-MANIFEST v[0-9]+$/{f=1;next} f&&/^```/{exit} f&&NF&&!/^#/' docs/WITNESS-MANIFEST.md 2>/dev/null | grep -c . ;;
    hooks_wired)  jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' .claude/settings.json 2>/dev/null | grep -c . ;;
    map_rows)     awk '/^# SYNC-MAP v[0-9]+$/{f=1;next} f&&/^```/{exit} f&&NF' docs/SYNC-CORRELATION.md 2>/dev/null | grep -c . ;;
    fixtures)     git ls-files '.claude/skills/packs/*/fixtures/attack/*.md' 2>/dev/null | grep -v '/README.md$' | grep -c . ;;
    *)            return 1 ;;
  esac
}

case "$MODE" in
prepare)
  echo "== distill delta — ledgers newer than the summary =="
  for f in PROGRESS.md Plan.md GATES.md; do
    [ -f "$f" ] || continue
    if [ "$f" -nt "$SUM" ]; then printf '  CHANGED  %s\n' "$f"; else printf '  current  %s\n' "$f"; fi
  done
  cat <<'INS'

== DISTILL INSTRUCTION (binding) ==
  Rewrite context/session-summary.md so it states CONCLUSIONS, not chronology:
   1. MERGE into the existing sections. Do not append a dated block — merging prevents compounded
      drift and appending causes it.
   2. Mark resolved items resolved and DELETE superseded claims. A summary that keeps every past
      belief is a transcript.
   3. Label every entry **verified** or **proposed**. An unverified claim silently promoted to fact
      across sessions is the hallucination vector these labels close.
   4. Repo-relative paths only. No raw log lines, no diffs.
   5. Write every NUMBER as **value** followed by its label, and declare it in context/CLAIMS.md.
      An undeclared number fails the check — that is the point.
   6. End with a single "## Next action".
  Then run: ./scripts/distill.sh check
INS
  ;;
check)
  echo "== distill: fidelity, not tidiness =="
  [ -f "$SUM" ] && ok "entry point $SUM exists" || { no "entry point missing"; }
  grep -q '^## Next action' "$SUM" 2>/dev/null && ok "summary declares a Next action" || no "no '## Next action' section"
  grep -qE '\*\*(verified|proposed)\*\*' "$SUM" 2>/dev/null && ok "summary carries verified/proposed labels" || no "no verified/proposed labels"
  grep -q "$ABS" "$SUM" 2>/dev/null && no "summary contains an absolute machine path" || ok "summary is free of absolute machine paths"
  grep -qE '^\{"ts"|^@@ |^\+\+\+ ' "$SUM" 2>/dev/null && no "summary contains raw log lines or diff hunks" || ok "summary carries no raw logs or diffs"

  ROWS=$(awk '/^# CLAIMS-MANIFEST v[0-9]+$/{f=1;next} f&&/^```/{exit} f&&NF&&!/^#/' "$CLAIMS" 2>/dev/null)
  NROW=$(printf '%s\n' "$ROWS" | grep -c . || true)
  # Vacuity guard: a manifest that parses to nothing binds nothing and every check below is clean.
  [ "${NROW:-0}" -ge 3 ] && ok "claims manifest parses to $NROW binding(s)" \
                         || no "claims manifest parsed to ${NROW:-0} rows — every fidelity check below would be vacuous"

  covered=""
  while IFS="$(printf '\t')" read -r id label ex; do
    [ -n "${id:-}" ] || continue
    want=$(truth "$ex") || { no "$id: unknown extractor '$ex' — a binding that names no source binds nothing"; continue; }
    got=$(grep -oE "\*\*[^*]+\*\* $label" "$SUM" 2>/dev/null | head -1 | sed -E 's/^\*\*([^*]+)\*\*.*/\1/')
    covered="$covered$label
"
    if [ -z "$got" ]; then
      # A declared binding whose claim is absent is reported, not skipped. Silence here is how a
      # fidelity check quietly stops meaning anything.
      ok "$id: summary makes no '$label' claim — nothing to bind"
    elif [ -z "$want" ]; then
      no "$id: summary claims '$got $label' but the source produced nothing to check it against"
    elif [ "$got" = "$want" ]; then
      ok "$id: '$label' matches its source ($want)"
    else
      no "$id: summary says '$got $label', the source says '$want'"
    fi
  done <<EOF
$ROWS
EOF

  # COMPLETENESS — the CR-034 lesson made structural. Every bold NUMBER in the summary must be
  # covered by a declared binding. Adding an unbound number is what fails.
  # STATED LIMIT: only numbers written in the bound form **value** label are checked. A number in
  # running prose is invisible here, and that is a real gap rather than a hidden one.
  unbound=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    lab=$(printf '%s' "$c" | sed -E 's/^\*\*[^*]+\*\* //')
    # PREFIX match, not exact. A binding declares the label; the sentence may continue past it
    # ("**7** wired hook commands across five events"). Requiring an exact match would force stilted
    # prose, and prose that fights its checker is prose that gets rewritten to dodge it.
    hit=0
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      case "$lab" in "$d"*) hit=1; break ;; esac
    done <<COV
$covered
COV
    [ "$hit" = 1 ] || unbound="$unbound [$lab]"
  done <<EOF
$(grep -oE '\*\*[0-9][^*]*\*\* [a-z][a-z0-9 _-]*' "$SUM" 2>/dev/null)
EOF
  [ -z "$unbound" ] && ok "every bold number in the summary is covered by a declared binding" \
                    || no "UNBOUND claim(s) in the summary:$unbound — declare them in $CLAIMS or remove them"

  printf '\n== distill: %s PASS / %s FAIL ==\n' "$P" "$F"
  [ "$F" = 0 ] || exit 1
  ;;
*) echo "usage: distill.sh [prepare|check]"; exit 64 ;;
esac
