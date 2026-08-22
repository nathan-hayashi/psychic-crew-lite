#!/usr/bin/env bash
# verify.sh — the three-layer verification entry point (plan §4).
#
#   layer 1  behavioural suites      scripts/validate-lite.sh + scripts/check-sync.sh
#   layer 2  witness manifest        scripts/check-witness.sh
#   layer 3  temporal history        docs/verification-history.jsonl  (this file, with --record)
#
# Layer 3 is the one the plan says this build has NOTHING of: without it nobody can answer "when did
# this control stop working". One append-only line per recorded run, carrying the commit, so a
# regression can be bisected to the change that introduced it rather than argued about.
#
# The history is TRACKED, not in logs/. A bisectable record that does not survive a clone is not a
# record — the same reason CR-006's data had to leave the parent's gitignored logs/.
#
# --record is explicit. Appending on every ad-hoc run would dirty the tree constantly and turn the
# history into noise; a recorded line should mean "this run was taken as an answer".
set -uo pipefail
cd "$(dirname "$0")/.."
REC=0; [ "${1:-}" = "--record" ] && REC=1
HIST="docs/verification-history.jsonl"

run () { # $1 = label, $2 = command -> sets OUT and RC
  printf '\n== %s ==\n' "$1"
  OUT=$($2 2>&1); RC=$?
  printf '%s\n' "$OUT" | tail -1
}

run "layer 1a — behavioural suite" "./scripts/validate-lite.sh"
l1p=$(printf '%s' "$OUT" | grep -oE '[0-9]+ PASS' | head -1 | grep -oE '[0-9]+')
l1s=$(printf '%s' "$OUT" | grep -oE '[0-9]+ SKIP' | head -1 | grep -oE '[0-9]+')
l1f=$(printf '%s' "$OUT" | grep -oE '[0-9]+ FAIL' | head -1 | grep -oE '[0-9]+')

run "layer 1b — parent correlation" "./scripts/check-sync.sh"
syp=$(printf '%s' "$OUT" | grep -oE '[0-9]+ PASS' | head -1 | grep -oE '[0-9]+')
syf=$(printf '%s' "$OUT" | grep -oE '[0-9]+ FAIL' | head -1 | grep -oE '[0-9]+')

run "layer 2 — witness manifest" "./scripts/check-witness.sh"
w2o=$(printf '%s' "$OUT" | grep -oE '[0-9]+ OK' | head -1 | grep -oE '[0-9]+')
w2s=$(printf '%s' "$OUT" | grep -oE '[0-9]+ STALE' | head -1 | grep -oE '[0-9]+')
w2f=$(printf '%s' "$OUT" | grep -oE '[0-9]+ FAIL' | head -1 | grep -oE '[0-9]+')

: "${l1p:=0}" "${l1s:=0}" "${l1f:=0}" "${syp:=0}" "${syf:=0}" "${w2o:=0}" "${w2s:=0}" "${w2f:=0}"

printf '\n== layer 3 — temporal history ==\n'
# THE SIGNAL THRESHOLD, stated rather than implied. The plan requires an explicit one and requires
# comparing against a ROLLING MEDIAN rather than the last run, so a single noisy run is not a
# regression.
#
#   signal  any FAIL, anywhere
#   signal  any STALE — an attestation that is unproven, which is not the same as broken
#   signal  layer-1 PASS count BELOW the median of the last 5 recorded runs
#   quiet   layer-1 PASS count at or ABOVE that median — assertions are expected to be added
med=""
# Counted once, defensively: `grep -c` prints 0 and ALSO exits 1 on no match, so the common
# `grep -c ... || echo 0` idiom yields the string "0\n0".
nhist=0; [ -f "$HIST" ] && nhist=$(grep -c . "$HIST" 2>/dev/null) ; nhist=${nhist:-0}
if [ "$nhist" -ge 3 ]; then
  med=$(jq -r '.layer1.pass' "$HIST" 2>/dev/null | tail -5 | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
fi
# Written as explicit ifs, not an `A || B && C` chain: that chain binds left to right and quietly
# assigns on the wrong branch, which is a bug in the code that decides whether anything is wrong.
sig=""
if [ "$l1f" -gt 0 ] || [ "$syf" -gt 0 ] || [ "$w2f" -gt 0 ]; then sig="$sig FAIL"; fi
if [ "$w2s" -gt 0 ]; then sig="$sig STALE"; fi
if [ -n "$med" ]; then
  if [ "$l1p" -lt "$med" ]; then
    sig="$sig REGRESSION(layer1 $l1p < rolling-median $med)"
  else
    printf '  layer-1 pass %s vs rolling median %s over the last %s runs — no regression signal\n' \
           "$l1p" "$med" "$( [ "$nhist" -lt 5 ] && echo "$nhist" || echo 5 )"
  fi
else
  printf '  rolling median needs 3 recorded runs; %s on file — comparison not yet possible, and said so rather than skipped\n' "$nhist"
fi

if [ "$REC" = 1 ]; then
  jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
         --arg c "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
         --argjson dirty "$(git status --porcelain 2>/dev/null | grep -c . || echo 0)" \
         --argjson l1p "$l1p" --argjson l1s "$l1s" --argjson l1f "$l1f" \
         --argjson syp "$syp" --argjson syf "$syf" \
         --argjson w2o "$w2o" --argjson w2s "$w2s" --argjson w2f "$w2f" \
    '{ts:$ts,commit:$c,dirty:$dirty,
      layer1:{pass:$l1p,skip:$l1s,fail:$l1f},
      sync:{pass:$syp,fail:$syf},
      layer2:{ok:$w2o,stale:$w2s,fail:$w2f}}' >> "$HIST"
  printf '  recorded to %s (%s entries)\n' "$HIST" "$(grep -c . "$HIST" 2>/dev/null)"
else
  printf '  not recorded — pass --record to append a bisectable line\n'
fi

printf '\n== verify: layer1 %s/%s/%s · sync %s/%s · layer2 %s/%s/%s ==\n' \
       "$l1p" "$l1s" "$l1f" "$syp" "$syf" "$w2o" "$w2s" "$w2f"
if [ -n "$sig" ]; then printf '== SIGNAL:%s ==\n' "$sig"; exit 1; fi
printf '== no signal ==\n'
