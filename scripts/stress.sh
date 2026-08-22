#!/usr/bin/env bash
# stress.sh — the L4 end-to-end run.
#
# WHAT THIS PROVES, stated before it runs so the result cannot be read as more than it is:
#   PROVEN   the cross-release law under real traffic — released_by != from_agent, enforced by the
#            shipped hook rather than by this harness, which routes every candidate line through
#            hooks/release-guard.sh and appends only what the guard permits.
#   PROVEN   blindness as a property of the PAYLOAD, not a promise: pass 2's dispatch file is
#            checked to contain none of pass 1's finding ids.
#   PROVEN   ordering — builder acts only after both releases exist, correlated by task_id.
#   PROVEN   the audit schema, every required field, full ISO-8601 to the second.
#   NOT PROVEN  that a model would find these defects. The findings are FIXTURE DATA scored against
#            an answer key fixed before the run (stress/DEFECTS.md). What is under test is the
#            machinery this build built, not the reviewer.
set -uo pipefail
cd "$(dirname "$0")/.."
# RUN-SCOPED, and this was wrong on the first version. The harness originally truncated
# logs/release-audit.jsonl — the LIVE trail — and wrote fixture releases into it, which is exactly
# the C-13 hazard the parent recorded when a fixture wrote 178 synthetic records into the trail it
# audits and the redaction then had to be logged to stay distinguishable from tampering. Fixture
# releases and real releases must never share a file: once mixed, no reader can tell which is which.
RUN="${LITE_STRESS_RUN:-logs/stress/$(date -u +%Y%m%dT%H%M%SZ)}"
TRAIL="$RUN/release-audit.jsonl"
DISP="$RUN/dispatch"
P=0; F=0
ok () { P=$((P+1)); printf '  [PASS] %s\n' "$1"; }
no () { F=$((F+1)); printf '  [FAIL] %s\n' "$1"; }
now () { date -u +%Y-%m-%dT%H:%M:%SZ; }
mkdir -p "$RUN" "$DISP"

# Every release attempt goes THROUGH the shipped guard. If the guard denies it, it is not written —
# so the law is enforced by the enforcement layer, not re-implemented here. A harness that
# reimplements the rule it is testing proves only that the harness agrees with itself.
release () { # $1 task_id  $2 from_agent  $3 released_by  $4 mutation  $5 reason
  line=$(jq -cn --arg ts "$(now)" --arg t "$1" --arg a "agent-$2-$$" --arg f "$2" \
                --arg r "$3" --arg m "$4" --arg n "$5" \
     '{ts:$ts,task_id:$t,agent_id:$a,from_agent:$f,released_by:$r,mutation:$m,reason:$n}')
  # The guard keys on the filename, so the payload names the real trail even though the write
  # lands in the run-scoped one. The guard's verdict is what is under test, not its path handling.
  out=$(jq -cn --arg c "$line" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}' \
        | ./hooks/release-guard.sh 2>/dev/null)
  case "$out" in
    *'"deny"'*) printf '%s' "REFUSED" ;;
    *) printf '%s\n' "$line" >> "$TRAIL"; printf '%s' "WROTE" ;;
  esac
}

echo "== L4 stress: end-to-end across four agents =="
: > "$TRAIL"
printf '  run-scoped trail: %s (the live trail is never touched)\n' "$TRAIL"
# Retention, same shape as the checkpoint hook's: keep the newest 5 runs. An end-to-end harness
# that accumulates a directory per invocation becomes its own disk problem.
ls -1dt logs/stress/*/ 2>/dev/null | tail -n +6 | while read -r old; do rm -rf "$old" 2>/dev/null || true; done

# --- 1. orchestrator dispatches. It releases NOTHING; it dispatches and consumes.
T_S1="L4-sec-pass1"; T_S2="L4-sec-pass2"; T_V1="L4-verify"
jq -cn --arg t "$T_S1" '{task_id:$t,to:"security",objective:"review stress/normalize.sh",
   inputs:["stress/normalize.sh"],expected_output:"FINDINGS schema, one object per finding"}' > "$DISP/$T_S1.json"
# Pass 2 is a SEPARATE dispatch and its payload deliberately carries the change and the contract and
# NOT the prior findings. That absence is what gets asserted below.
jq -cn --arg t "$T_S2" '{task_id:$t,to:"security",objective:"review stress/normalize.sh",
   inputs:["stress/normalize.sh"],expected_output:"FINDINGS schema, one object per finding",
   note:"second pass; prior findings deliberately withheld"}' > "$DISP/$T_S2.json"
ok "orchestrator wrote two separate dispatches ($T_S1, $T_S2)"

# --- 2. security pass 1 (lens: injection). Fixture content, scored against the fixed answer key.
jq -cn '{id:"F-1",agent:"security",severity:"med",dimension:"injection",
  claim:"fields interpolated into JSON without escaping",
  evidence:"stress/normalize.sh printf line",file:"stress/normalize.sh",
  failure_scenario:"a name containing a double quote emits malformed JSON that a consumer cannot parse",
  fix_proposal:"build the object with jq --arg",confidence:0.9,defect:"D-1"}' > "$DISP/$T_S1.findings.json"
# --- 3. security pass 2, BLIND (lens: behaviour under real input).
jq -cn '{id:"F-2",agent:"security",severity:"high",dimension:"correctness",
  claim:"read without -r and a dropped final line",
  evidence:"stress/normalize.sh while-read loop",file:"stress/normalize.sh",
  failure_scenario:"a file whose last line has no trailing newline silently loses that record",
  fix_proposal:"read -r, and process a final partial line",confidence:0.85,defect:"D-2"}' > "$DISP/$T_S2.findings.json"

# BLINDNESS, asserted against the artifact rather than promised. Pass 2's dispatch must contain no
# id, claim or defect tag from pass 1.
leak=""
for k in $(jq -r '.id, .claim, .defect' "$DISP/$T_S1.findings.json"); do
  grep -qF -- "$k" "$DISP/$T_S2.json" 2>/dev/null && leak="$leak [$k]"
done
[ -z "$leak" ] && ok "pass 2's dispatch payload carries nothing from pass 1 — blindness is a property of the payload" \
               || no "BLINDNESS BREACH: pass 2's dispatch contains$leak"

# --- 4. cross-release. verifier releases security's findings, because it did not produce them.
r1=$(release "$T_S1" security verifier "findings normalised, severity recalibrated" "pass 1 released by a party that did not produce it")
[ "$r1" = WROTE ] && ok "verifier released security pass 1 (cross-release accepted)" || no "cross-release was refused: $r1"
r2=$(release "$T_S2" security verifier "findings normalised, severity recalibrated" "pass 2 released, blind to pass 1")
[ "$r2" = WROTE ] && ok "verifier released security pass 2" || no "pass 2 release refused: $r2"

# --- 5. THE NEGATIVE CONTROL, run live inside the stress rather than beside it: security tries to
# release its own findings. The shipped guard must refuse, and nothing must reach the trail.
before=$(grep -c . "$TRAIL" 2>/dev/null); before=${before:-0}
r3=$(release "$T_S1" security security "self-release attempt" "a producer releasing its own output")
after=$(grep -c . "$TRAIL" 2>/dev/null); after=${after:-0}
{ [ "$r3" = REFUSED ] && [ "$after" = "$before" ]; } \
  && ok "a self-release was REFUSED by the shipped guard and never reached the trail" \
  || no "self-release was not stopped (verdict=$r3, trail $before -> $after)"

# --- 6. verifier runs the subject; security releases verifier's results.
got=$(printf 'u1\tA"B\tE@X.COM' | ./stress/normalize.sh 2>/dev/null | wc -l)
r4=$(release "$T_V1" verifier security "results normalised" "verifier results released by security")
[ "$r4" = WROTE ] && ok "security released verifier's results (the reciprocal direction)" || no "reciprocal release refused: $r4"

# --- 7. ORDERING: builder may act only once both producers' output has been released.
rel_s=$(jq -r --arg t "$T_S1" 'select(.task_id==$t and .from_agent=="security") | .released_by' "$TRAIL" | head -1)
rel_v=$(jq -r --arg t "$T_V1" 'select(.task_id==$t and .from_agent=="verifier") | .released_by' "$TRAIL" | head -1)
{ [ "$rel_s" = verifier ] && [ "$rel_v" = security ]; } \
  && ok "builder's precondition holds — both producers released by the other ($rel_s / $rel_v)" \
  || no "builder's precondition NOT met (security released by '$rel_s', verifier by '$rel_v')"

# --- 8. schema and law over the whole trail.
n=$(grep -c . "$TRAIL"); ok "trail carries $n released line(s)"
bad=$(jq -r 'select(.from_agent == .released_by) | .task_id' "$TRAIL" | tr '\n' ' ')
[ -z "$bad" ] && ok "no self-release anywhere in the trail" || no "SELF-RELEASE present for:$bad"
miss=$(jq -r 'select((.ts|test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")|not)
              or (.task_id//"")=="" or (.agent_id//"")=="" or (.mutation//"")=="") | .task_id' "$TRAIL" | tr '\n' ' ')
[ -z "$miss" ] && ok "every line carries the full schema with ISO-8601 to the second" || no "schema defects at:$miss"
ids=$(jq -r '.task_id' "$TRAIL" | sort -u | wc -l)
[ "$ids" -ge 3 ] && ok "coverage correlates by task_id identity, not count ($ids distinct)" || no "only $ids distinct task_id(s)"

# --- 9. SCORE against the answer key fixed before the run.
key=$(grep -oE '^\| `D-[0-9]+`' stress/DEFECTS.md | grep -oE 'D-[0-9]+' | sort -u)
found=$(cat "$DISP"/*.findings.json 2>/dev/null | jq -r '.defect' | sort -u)
nk=$(printf '%s\n' "$key" | grep -c .); nf=$(printf '%s\n' "$found" | grep -c .)
missed=$(comm -23 <(printf '%s\n' "$key") <(printf '%s\n' "$found") | tr '\n' ' ')
[ "$nk" -ge 2 ] && ok "answer key parsed: $nk seeded defect(s), fixed before the run" || no "answer key did not parse ($nk)"
[ -z "$missed" ] && ok "both passes together account for every seeded defect ($nf/$nk)" || no "unfound seeded defect(s):$missed"
# The union is the point: EITHER pass alone misses one.
p1=$(jq -r '.defect' "$DISP/$T_S1.findings.json"); p2=$(jq -r '.defect' "$DISP/$T_S2.findings.json")
[ "$p1" != "$p2" ] && ok "the two passes found DIFFERENT defects ($p1 vs $p2) — the union is what a single pass would have missed" \
                   || no "both passes found the same defect ($p1) — the second bought nothing"

printf '\n== stress: %s PASS / %s FAIL ==\n' "$P" "$F"
[ "$F" = 0 ] || exit 1
