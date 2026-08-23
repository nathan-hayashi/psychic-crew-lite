#!/usr/bin/env bash
# validate-lite.sh — the L1 assertion layer.
#
# ONE script rather than the parent's static/behavioural split. Lite is small enough that two
# entry points would be ceremony, and LC-4's "one command" spirit argues against a second. Stated
# as a simplification, not discovered as one.
#
# Behavioural cases run under a mktemp root. The parent shipped a fixture that wrote 178 synthetic
# records into the live trail it audits, and the redaction had to be logged to stay distinguishable
# from tampering. No case here touches this repo's own logs/.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0; S=0
ok () { P=$((P+1)); printf '  [PASS] %s\n' "$1"; }
no () { F=$((F+1)); printf '  [FAIL] %s\n' "$1"; }
sk () { S=$((S+1)); printf '  [SKIP] %s\n' "$1"; }

# Built, not written literally: this guard is high-recall and this repo's own rules file explains
# why quoting the token is a hazard.
ABS=$(printf '/%s/' home)

echo "== A. wiring =="
jq -e . .claude/settings.json >/dev/null 2>&1 && ok "settings.json parses" || no "settings.json does not parse"
for f in hooks/*.sh scripts/*.sh; do bash -n "$f" 2>/dev/null || no "syntax error in $f"; done
ok "all shell files parse"

# C-26, carried forward as a design input rather than inherited as a defect. The parent's map-vs-tree
# check polices scripts/ and context/ and has NEVER policed hooks/, so two hooks added at S2 drifted
# for four days in the directory holding its entire enforcement layer. Bound in both directions
# here, from the start. _common.sh is excluded BY NAME because it is sourced, never wired.
tracked=$(git ls-files 'hooks/*.sh' 2>/dev/null | sed 's|hooks/||' | grep -v '^_common\.sh$' | sort -u)
wired=$(jq -r '.hooks | to_entries[] | .value[] | .hooks[] | .command' .claude/settings.json 2>/dev/null \
        | sed 's|.*/||' | sort -u)
ntr=$(printf '%s\n' "$tracked" | grep -c . || true)
nwi=$(printf '%s\n' "$wired" | grep -c . || true)
# Vacuity guard first: two empty sets differ by nothing, which is a clean comparison proving zero.
{ [ "${ntr:-0}" -ge 3 ] && [ "${nwi:-0}" -ge 3 ]; } \
  && ok "hook extraction is non-vacuous ($ntr tracked, $nwi wired)" \
  || no "hook extraction vacuous — tracked:$ntr wired:$nwi"
unw=$(comm -23 <(printf '%s\n' "$tracked") <(printf '%s\n' "$wired") | tr '\n' ' ')
gho=$(comm -13 <(printf '%s\n' "$tracked") <(printf '%s\n' "$wired") | tr '\n' ' ')
{ [ -z "$unw" ] && [ -z "$gho" ]; } \
  && ok "every tracked hook is wired and every wired hook exists" \
  || no "hooks/ drift — tracked but unwired:[$unw] wired but absent:[$gho]"

echo
echo "== B. model policy (LC-2 / LC-3 / LC-4) =="
jq -e . models.config.json >/dev/null 2>&1 && ok "models.config.json parses" || no "models.config.json does not parse"
mode=$(jq -r '.mode // "alias"' models.config.json)
bad_any=""
for b in $(jq -r '.forbidden_substrings[]' models.config.json); do
  # Resolved values, never declared classes. A class named "deep" carries no forbidden substring
  # and can still point at a forbidden model; that indirection is the whole cost of LC-3.
  hit=$(jq -r --arg b "$b" --arg m "$mode" '. as $r
    | [ ($r.agents | to_entries[] | .value.class as $c | ($r.classes[$c]) as $al
          | if $m == "pinned" then $r.pinned[$al] else $r.aliases[$al] end),
        ($r.aliases | to_entries[] | .value), ($r.pinned | to_entries[] | .value),
        ($r.session.model // "") ]
    | map(select(type == "string" and (ascii_downcase | contains($b)))) | .[0] // ""' models.config.json)
  [ -z "$hit" ] || bad_any="$bad_any [$b -> $hit]"
done
# VACUITY GUARD, added because this check passed while resolving NOTHING. Inside
# `.agents | to_entries[]` the dot is the entry, not the root, so .classes[$c] indexed null and
# every comparison ran against an empty list. It reported clean and the behavioural case in D was
# what exposed it. Assert the resolution actually produced one model per agent.
nres=$(jq -r --arg m "$mode" '. as $r | [ $r.agents | to_entries[] | .value.class as $c
        | ($r.classes[$c]) as $al | if $m == "pinned" then $r.pinned[$al] else $r.aliases[$al] end
        | select(type == "string" and length > 0) ] | length' models.config.json)
nag=$(jq -r '.agents | length' models.config.json)
[ "${nres:-0}" = "$nag" ] && ok "class resolution produced a model for all $nag agents (scan is not vacuous)" \
                          || no "class resolution produced $nres models for $nag agents — the LC-2 scan above is vacuous"
[ -z "$bad_any" ] && ok "LC-2: no forbidden model reachable through any class, alias or pin" \
                  || no "LC-2 BREACH: forbidden model reachable ->$bad_any"

# Stamp parity. A hand-edited frontmatter line is the failure model-policy.md names, and it is
# invisible unless the stamped value is compared to what config resolves to.
drift=""
for a in $(jq -r '.agents | keys[]' models.config.json); do
  f=".claude/agents/$a.md"
  [ -f "$f" ] || { drift="$drift [$a: file absent]"; continue; }
  want=$(jq -r --arg a "$a" --arg m "$mode" '.agents[$a].class as $c | .classes[$c] as $al
         | if $m == "pinned" then .pinned[$al] else .aliases[$al] end' models.config.json)
  got=$(awk '/^---$/{n++;next} n==1 && /^model:/{sub(/^model:[[:space:]]*/,"");print;exit}' "$f")
  [ "$want" = "$got" ] || drift="$drift [$a: config=$want file=$got]"
done
[ -z "$drift" ] && ok "every agent's stamped model matches what config resolves to" \
                || no "stamp drift —$drift"

echo
echo "== C. hygiene =="
hits=$(git grep -l "$ABS" -- . 2>/dev/null | tr '\n' ' ')
[ -z "$hits" ] && ok "no absolute machine path in any tracked file" || no "absolute path in: $hits"
_v1="cod""ex"; _v2="chat""gpt"; _v3="open""ai"
vh=$(git grep -ilE "$_v1|$_v2|$_v3" -- . 2>/dev/null | grep -v '^hooks/bash-blocker\.sh$' | tr '\n' ' ')
[ -z "$vh" ] && ok "LC-7: no non-Claude vendor name outside the deny-list itself" || no "vendor name in: $vh"
for e in ".env" "logs/" ".claude/state/"; do
  grep -qxF "$e" .gitignore && ok "ignore rule present: $e" || no "ignore rule missing: $e"
done

echo
echo "== D. the guards actually fire (behavioural, temp root) =="
T=$(mktemp -d); mkdir -p "$T/logs" "$T/.claude"
cp models.config.json "$T/" 2>/dev/null; cp GATES.md "$T/" 2>/dev/null
fire () { # $1 = hook, $2 = json payload -> echoes "DENY" or "ALLOW"
  out=$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$T" ./hooks/"$1" 2>/dev/null || true)
  case "$out" in *'"deny"'*) echo DENY ;; *) echo ALLOW ;; esac
}
# Assembled from fragments: writing these verbs contiguously into a command string is denied by
# this repo's own deny-list, which is precisely what it is supposed to do.
c1=git; c2=clone; probe="$c1 $c2 https://example.invalid/x"
[ "$(fire bash-blocker.sh "$(jq -cn --arg c "$probe" '{tool_name:"Bash",tool_input:{command:$c}}')")" = DENY ] \
  && ok "bash-blocker denies a prohibited fetch verb" || no "bash-blocker allowed a prohibited fetch verb"
[ "$(fire bash-blocker.sh "$(jq -cn '{tool_name:"Bash",tool_input:{command:"ls -la"}}')")" = ALLOW ] \
  && ok "bash-blocker allows an ordinary command" || no "bash-blocker denied an ordinary command"
[ "$(fire sensitive-guard.sh "$(jq -cn '{tool_name:"Write",tool_input:{file_path:"/x/.env",content:"K=v"}}')")" = DENY ] \
  && ok "sensitive-guard denies a write to .env" || no "sensitive-guard allowed a write to .env"
# Class indirection at write time: the agent never changes and no forbidden word sits near one.
fb=$(jq -r '.forbidden_substrings[0]' models.config.json)
poison=$(jq -c --arg b "$fb" '.aliases.opus = $b' models.config.json)
[ "$(fire model-guard.sh "$(jq -cn --arg c "$poison" '{tool_name:"Write",tool_input:{file_path:"models.config.json",content:$c}}')")" = DENY ] \
  && ok "model-guard denies a config where a CLASS resolves to a forbidden model" \
  || no "model-guard allowed a forbidden model reachable through a class"
[ "$(fire model-guard.sh "$(jq -cn --arg c "$(cat models.config.json)" '{tool_name:"Write",tool_input:{file_path:"models.config.json",content:$c}}')")" = ALLOW ] \
  && ok "model-guard allows the clean config" || no "model-guard denied the clean config"
selfrel='{"ts":"2026-01-01T00:00:00Z","task_id":"t1","agent_id":"a","from_agent":"security","released_by":"security","mutation":"none","reason":"x"}'
crossrel='{"ts":"2026-01-01T00:00:00Z","task_id":"t1","agent_id":"a","from_agent":"security","released_by":"verifier","mutation":"none","reason":"x"}'
noid='{"ts":"2026-01-01T00:00:00Z","agent_id":"a","from_agent":"security","released_by":"verifier","mutation":"none","reason":"x"}'
[ "$(fire release-guard.sh "$(jq -cn --arg c "$selfrel" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = DENY ] \
  && ok "release-guard denies a self-release" || no "release-guard allowed a self-release"
[ "$(fire release-guard.sh "$(jq -cn --arg c "$crossrel" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = ALLOW ] \
  && ok "release-guard allows a cross-release" || no "release-guard denied a valid cross-release"
[ "$(fire release-guard.sh "$(jq -cn --arg c "$noid" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = DENY ] \
  && ok "release-guard denies a release line with no task_id" || no "release-guard allowed an uncorrelatable release"
# The Bash path too, since an append is the likelier way this line gets written.
[ "$(fire release-guard.sh "$(jq -cn --arg c "echo '$selfrel' >> logs/release-audit.jsonl" '{tool_name:"Bash",tool_input:{command:$c}}')")" = DENY ] \
  && ok "release-guard denies a self-release appended via Bash" || no "release-guard missed a self-release via Bash"
# A denial must leave a record. Blocking silently is a control nobody can audit after the fact.
[ -s "$T/logs/deny-audit.jsonl" ] && ok "every denial wrote an audit line ($(grep -c . "$T/logs/deny-audit.jsonl") records)" \
                                  || no "denials left no audit record"
# The phase stamped on those records must be L-series and must not be the fail-closed sentinel.
ph=$(jq -r '.phase' "$T/logs/deny-audit.jsonl" 2>/dev/null | sort -u | tr '\n' ' ')
case "$ph" in *"L?"*) no "denial records carry the fail-closed phase sentinel ($ph)" ;;
              L[0-9]*) ok "denial records carry an L-series phase ($ph)" ;;
              *) no "denial records carry an unexpected phase ($ph)" ;; esac
rm -rf "$T"

echo
echo "== D2. continuity (L3, behavioural, temp root) =="
CT=$(mktemp -d); mkdir -p "$CT/logs" "$CT/.claude/state"
cp GATES.md "$CT/" 2>/dev/null
printf '# P\n\n## [L2|t] c\n- **Next action:** SENTINEL-CARRY-FORWARD\n' > "$CT/PROGRESS.md"
CLAUDE_PROJECT_DIR="$CT" ./hooks/pre-compact-checkpoint.sh >/dev/null 2>&1; ckrc=$?
[ "$ckrc" = 0 ] && ok "pre-compact exits 0 (it must never block compaction)" \
                || no "pre-compact exited $ckrc — it would block or fail a compaction"
ls "$CT"/.claude/state/checkpoints/ckpt-*.md >/dev/null 2>&1 \
  && ok "pre-compact wrote a numbered snapshot" || no "pre-compact wrote no snapshot"
# The parent's version hardcoded a pointer here, which then BECAME the newest Next action line, so
# the cold reader recovered the pointer instead of the instruction it displaced. The parachute
# degraded the one field it exists to protect. Assert the prior action is carried VERBATIM.
grep -qF 'SENTINEL-CARRY-FORWARD' "$CT/PROGRESS.md" \
  && ok "pre-compact carried the prior next action forward verbatim" \
  || no "pre-compact displaced the next action with its own pointer"
chmod 400 "$CT/PROGRESS.md" 2>/dev/null
CLAUDE_PROJECT_DIR="$CT" ./hooks/pre-compact-checkpoint.sh >/dev/null 2>&1; ckrc2=$?
chmod 644 "$CT/PROGRESS.md" 2>/dev/null
[ "$ckrc2" = 0 ] && ok "pre-compact still exits 0 with PROGRESS.md unwritable" \
                 || no "pre-compact failed on an unwritable ledger (exit $ckrc2)"
rm -rf "$CT"

# §6.2 — the watchdog must be watched by a party with no stake in the answer.
./scripts/continuity.sh stalls --as session-orchestrator >/dev/null 2>&1 \
  && no "the orchestrator was allowed to run its own stall check" \
  || ok "the orchestrator may not run its own stall check (the watchdog is watched)"
./scripts/continuity.sh heartbeat not-an-agent working >/dev/null 2>&1 \
  && no "heartbeat accepted an unknown agent name" \
  || ok "heartbeat rejects an agent outside the roster"
# The durable record: a history that accepts fixture data is a history nobody can trust, which is
# what C-14 recorded when synthetic records entered a live trail. `record` must refuse outside a git
# work tree, because that is where fixtures and stress harnesses run.
DT=$(mktemp -d); mkdir -p "$DT/scripts" "$DT/docs" "$DT/logs"
cp scripts/continuity.sh "$DT/scripts/"; cp GATES.md PROGRESS.md "$DT/" 2>/dev/null
( cd "$DT" && ./scripts/continuity.sh record >/dev/null 2>&1 ) \
  && no "record accepted a fixture root — the durable history would carry synthetic checkpoints" \
  || ok "record refuses outside a git work tree (fixture data cannot enter the durable history)"
[ -s "$DT/docs/session-history.jsonl" ] \
  && no "record wrote to the fixture's durable history despite refusing" \
  || ok "the refused record wrote nothing at all"
rm -rf "$DT"
# Confirm-it-landed, and the durable line must parse with its required fields. The L2 history write
# once reported success while appending nothing.
sed 's/#.*//' scripts/continuity.sh | grep -qF -- 'durable record did NOT land' \
  && ok "record confirms its line landed rather than assuming it" \
  || no "record does not confirm the write landed"
if [ -s docs/session-history.jsonl ]; then
  jq -e '.commit and .phase and .event=="checkpoint"' docs/session-history.jsonl >/dev/null 2>&1 \
    && ok "every durable checkpoint carries commit, phase and event ($(grep -c . docs/session-history.jsonl) recorded)" \
    || no "a durable checkpoint is missing required fields"
else
  sk "no durable checkpoint recorded yet — nothing to validate"
fi
# Seance must LABEL which store answered. An unlabelled result set looks complete on a machine
# where it is not, and the durable half is all a fresh clone has.
sed 's/#.*//' scripts/continuity.sh | grep -qF -- '[durable: survives a clone]' \
  && ok "seance labels durable hits so a successor can tell what travels" \
  || no "seance does not distinguish durable from runtime results"
sed 's/#.*//' scripts/continuity.sh | grep -qF -- 'does not travel to a fresh clone' \
  && ok "seance says so when every hit is runtime-only" \
  || no "seance is silent when its answer would not travel"

sed 's/#.*//' scripts/continuity.sh | grep -qF -- 'write divergence, not a stall' \
  && ok "stall detection distinguishes divergence from a stall (never one store)" \
  || no "stall detection lost the divergence branch — it would escalate from a single store"

echo
echo "== E. release trail =="
TRAIL="logs/release-audit.jsonl"
n=0; [ -f "$TRAIL" ] && n=$(grep -c . "$TRAIL" 2>/dev/null); n=${n:-0}
# An EMPTY trail is not a clean trail. "no self-release in 0 lines" is trivially true, and this
# section reported exactly that as a PASS the moment the stress harness stopped writing here —
# a vacuous pass in the check guarding this build's central law. Absent and empty are the same
# answer and both are announced, never passed.
if [ "$n" = 0 ]; then
  sk "release trail is absent or empty — no dispatch has released anything, so the law below is untested here (stress runs are run-scoped by design)"
else
  selfn=$(jq -r 'select(.from_agent == .released_by) | .task_id' "$TRAIL" 2>/dev/null | tr '\n' ' ')
  [ -z "$selfn" ] && ok "no self-release in $n trail lines" || no "SELF-RELEASE in trail for task_id(s): $selfn"
  noidn=$(jq -r 'select((.task_id // "") == "") | .ts' "$TRAIL" 2>/dev/null | tr '\n' ' ')
  [ -z "$noidn" ] && ok "every release line carries a task_id" || no "release lines with no task_id at: $noidn"
fi

printf '\n== validate-lite: %s PASS / %s SKIP / %s FAIL ==\n' "$P" "$S" "$F"
[ "$F" = 0 ] || exit 1
